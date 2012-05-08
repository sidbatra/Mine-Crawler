#!/usr/bin/env ruby

require 'rubygems'
require 'aws/s3'


if ARGV.length < 2
  puts "Usage - ruby automate.rb <environment> <seed.txt path>"
  exit
elsif !["staging","production"].include?(ARGV[0])
  puts "Invalid environment. Valid options - staging,production"
  exit
end

@env = ARGV[0]
@seed_path = ARGV[1]

@name = "1336513522" #Time.now.to_i.to_s
@bucket = "denwen-mine-crawler-#{@env}"
@job_id = ""


puts @env,@seed_path,@name,@bucket



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

#puts `cd apache-nutch-1.4-bin && ant`


#############################
# Launch EMR Hadoop cluster
#############################

command = "./elastic-mapreduce/elastic-mapreduce --create "\
          "--hive-interactive "\
          "--alive "\
          "--name 'Crawl #{@env.capitalize} #{@name}' "\
          "--master-instance-type m1.small "\
          "--slave-instance-type m1.small "\
          "--num-instances 1  "\
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
  sleep 15

  puts output = `./elastic-mapreduce/elastic-mapreduce --list #{@job_id}`
  state = output.split[1]

  if state == "TERMINATED" || state == "FAILED" || state == "SHUTTING_DOWN"
    puts "Error booting up EMR cluster"
    exit
  end
end

# upload resources to master - mr scripts, hive script, nutch deploy folder
# scp -i /home/sbat/.ssh/id_ec2_bootup -r apache-nutch-1.4-bin/runtime/deploy/ hadoop@ec2-23-20-24-12.compute-1.amazonaws.com:~
# scp -i /home/sbat/.ssh/id_ec2_bootup scripts/hive.sql scripts/mr/extract_products.rb   hadoop@ec2-23-20-24-12.compute-1.amazonaws.com:~


# run crawl.sh on master with correct folder.

# wait until crawl finishes. 
# download extracted products distributed table.
# insert into products db
