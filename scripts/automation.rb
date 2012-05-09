#!/usr/bin/env ruby

require 'rubygems'
require 'aws/s3'


if ARGV.length < 3
  puts "Usage - ruby automate.rb <environment> <seed.txt path> <pem file path>"
  exit
elsif !["staging","production"].include?(ARGV[0])
  puts "Invalid environment. Valid options - staging,production"
  exit
end

@env = ARGV[0]
@seed_path = ARGV[1]
@key_pair_path = ARGV[2]

@name = Time.now.to_i.to_s
@bucket = "denwen-mine-crawler-#{@env}"
@job_id = ""


puts @env,@seed_path,@key_pair_path,@name,@bucket



#############################
# Upload resources to S3 
#############################

AWS::S3::Base.establish_connection!(
  :access_key_id     => "AKIAJWYCAWDPAAKLNKSQ",
  :secret_access_key => "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")

AWS::S3::S3Object.store(
  "#{@name}/bootstrap.sh",
  open("scripts/bootstrap.sh"),
  @bucket)

AWS::S3::S3Object.store(
  "#{@name}/urls/seed.txt",
  open(@seed_path),
  @bucket)



#############################
# Build nutch
#############################

puts `cd apache-nutch-1.4-bin && ant`


#############################
# Launch EMR Hadoop cluster
#############################

command = "./elastic-mapreduce/elastic-mapreduce --create "\
          "--hive-interactive "\
          "--alive "\
          "--name 'Crawl #{@env.capitalize} #{@name}' "\
          "--master-instance-type m1.small "\
          "--slave-instance-type m1.small "\
          "--num-instances 10  "\
          "--key-pair ec2-bootup "\
          "--availability-zone us-east-1b "\
          "--log-uri s3n://#{@bucket}/#{@name}/logs "\
          "--enable-debugging "\
          "--bootstrap-action s3n://elasticmapreduce/bootstrap-actions/configure-hadoop "\
          "--arg --site-key-value "\
          "--arg mapred.reduce.tasks.speculative.execution=false "\
          "--arg --mapred-key-value "\
          "--arg mapred.reduce.tasks.speculative.execution=false "\
          "--bootstrap-action s3n://#{@bucket}/#{@name}/bootstrap.sh"

puts output = `#{command}`

if output.start_with? "Created"
  @job_id = output.split.last
else
  puts "Error launching EMR cluster"
  exit
end


#############################
# Wait for cluster bootup
#############################

state = ""

while state != "WAITING"
  sleep 30

  puts output = `./elastic-mapreduce/elastic-mapreduce --list #{@job_id}`
  state = output.split[1]

  if state == "TERMINATED" || state == "FAILED" || state == "SHUTTING_DOWN"
    puts "Error booting up EMR cluster"
    exit
  end
end


#############################
# Upload resources to cluster
#############################

command = "./elastic-mapreduce/elastic-mapreduce #{@job_id} "\
          "--key-pair-file #{@key_pair_path} "\
          "--scp scripts/ "\
          "--to /home/hadoop "\
          "--scp apache-nutch-1.4-bin/runtime/deploy/ "\
          "--to /home/hadoop"

puts `#{command}`
          

#############################
# Launch crawl
#############################

command = "./elastic-mapreduce/elastic-mapreduce #{@job_id} "\
          "--key-pair-file #{@key_pair_path} "\
          "--ssh 'sh -c \"cd /home/hadoop ; nohup ruby scripts/crawl.rb #{@env} #{@name} #{@bucket} > crawl.txt 2>&1 &\"'"

puts `#{command}`





# download extracted products distributed table.
# insert into products db
