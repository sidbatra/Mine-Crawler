#!/usr/bin/env ruby

require 'rubygems'
require 'logger'
require 'aws/s3'
require 'yaml'
require 'base64'


if ARGV.length < 4
  puts "Usage - ruby automate.rb <environment> <seed.txt path> "\
        "<hash.txt path> <name>"
  exit
elsif !["staging","production"].include?(ARGV[0])
  puts "Invalid environment. Valid options - staging,production"
  exit
end


ROOT_PATH = File.join(File.dirname(__FILE__),"../")

@env = ARGV[0]
@seed_path = ARGV[1]
@hash_path = ARGV[2]
@name = ARGV[3]

@bucket = "denwen-mine-crawler-#{@env}"
@nutch_path = "./apache-nutch-1.5-bin"
@job_id = ""
@key_pair_path = "~/.ssh/id_ec2_bootup"
@log_path = File.join(ROOT_PATH,"log/automation-#{@name}.rb.log")
@logger = Logger.new @log_path

if @env.start_with? 'p'
  @instances = 1
  @spot_instances = 0
  @spot_price = 0.04
else
  @instances = 1
  @spot_instances = 0
  @spot_price = 0.04
end


@logger.info [@env,@seed_path,@hash_path,@key_pair_path,
              @name,@bucket,@instances].join("\n")

CONFIG = YAML.load_file(File.join(ROOT_PATH,"config/config.yml"))[@env]


#############################
# Upload resources to S3 
#############################

AWS::S3::Base.establish_connection!(
  :access_key_id     => CONFIG[:aws_access_id],
  :secret_access_key => CONFIG[:aws_secret_key])

AWS::S3::S3Object.store(
  "#{@name}/bootstrap.sh",
  open("scripts/bootstrap.sh"),
  @bucket)

AWS::S3::S3Object.store(
  "#{@name}/urls/seed.txt",
  open(@seed_path),
  @bucket)

AWS::S3::S3Object.store(
  "#{@name}/hash.txt",
  open(@hash_path),
  @bucket)



#############################
# Build nutch
#############################

@logger.info `cd #{@nutch_path} && ant`
@logger.info `mv #{@nutch_path}/runtime/deploy/apache-nutch-1.5.job #{@nutch_path}/runtime/deploy/nutch-1.5.job`



#############################
# Launch EMR Hadoop cluster
#############################

command = "./elastic-mapreduce/elastic-mapreduce --create "\
          "--hive-interactive "\
          "--alive "\
          "--name 'Crawl #{@env.capitalize} #{@name}' "\
          "--master-instance-type m2.2xlarge "\
          "--slave-instance-type c1.medium "\
          "--num-instances #{@instances} "\
          "--key-pair ec2-bootup "\
          "--availability-zone us-east-1b "\
          "--log-uri s3n://#{@bucket}/#{@name}/logs "\
          "--enable-debugging "\
          "--bootstrap-action s3n://elasticmapreduce/bootstrap-actions/configure-hadoop "\
          "--arg --site-key-value "\
          "--arg mapred.reduce.tasks.speculative.execution=false "\
          "--arg --mapred-key-value "\
          "--arg mapred.reduce.tasks.speculative.execution=false "\
          "--arg --site-key-value "\
          "--arg mapred.child.java.opts=-Xmx2048m "\
          "--arg --mapred-key-value "\
          "--arg mapred.child.java.opts=-Xmx2048m "\
          "--arg --site-key-value "\
          "--arg mapred.tasktracker.map.tasks.maximum=10 "\
          "--arg --mapred-key-value "\
          "--arg mapred.tasktracker.map.tasks.maximum=10 "\
          "--arg --site-key-value "\
          "--arg mapred.tasktracker.reduce.tasks.maximum=4 "\
          "--arg --mapred-key-value "\
          "--arg mapred.tasktracker.reduce.tasks.maximum=4 "\
          "--bootstrap-action s3n://#{@bucket}/#{@name}/bootstrap.sh "\
          "--arg s3n://#{@bucket}/#{@name}/hash.txt"

          #"--instance-group task --instance-type m1.small "\
          #"--instance-count #{@spot_instances} --bid-price #{@spot_price} "\

@logger.info output = `#{command}`

if output.start_with? "Created"
  @job_id = output.split.last
else
  @logger.info "Error launching EMR cluster"
  exit
end


#############################
# Wait for cluster bootup
#############################

state = ""

while state != "WAITING"
  sleep 30

  @logger.info output = `./elastic-mapreduce/elastic-mapreduce --list #{@job_id}`
  state = output.split[1]

  if state == "TERMINATED" || state == "FAILED" || state == "SHUTTING_DOWN"
    @logger.info "Error booting up EMR cluster"
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
          "--scp #{@nutch_path}/runtime/deploy/ "\
          "--to /home/hadoop "\
          "--scp external/ "\
          "--to /home/hadoop "\
          "--scp config/ "\
          "--to /home/hadoop "

@logger.info `#{command}`
          

#############################
# Launch crawl
#############################

command = "./elastic-mapreduce/elastic-mapreduce #{@job_id} "\
          "--key-pair-file #{@key_pair_path} "\
          "--ssh 'sh -c \"cd /home/hadoop ; nohup ruby scripts/crawl.rb #{@env} #{@name} #{@bucket} #{Base64.encode64(@job_id).chomp} > crawl.txt 2>&1 &\"'"

@logger.info `#{command}`



# Make sure logs are written.
sleep 5

#############################
# Upload launch log
#############################

AWS::S3::S3Object.store(
  "#{@name}/launch.txt",
  open(@log_path),
  @bucket)

