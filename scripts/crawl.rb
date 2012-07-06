#!/usr/bin/env ruby

require 'rubygems'
require 'yaml'
require 'base64'
require 'aws'
require '/home/hadoop/external/fifo/lib/fifo.rb'

if ARGV.length < 4
  puts "Usage - ruby crawl.rb <environment> <name> <bucket> <job_id> "
  exit
elsif !["staging","production"].include?(ARGV[0])
  puts "Invalid environment. Valid options - staging,production"
  exit
end

@env = ARGV[0]
@name = ARGV[1]
@bucket = ARGV[2]
@job_id = Base64.decode64(ARGV[3])

puts @env,@name,@bucket,@job_id


CONFIG = YAML.load_file("/home/hadoop/config/config.yml")[@env]


if @env.start_with? "s"
  @depth = 5
  @top_n = 250
  @threads = 50
else
  @depth = 15
  @top_n = 1000000
  @threads = 500
end

@nutch_bin = "deploy/bin/nutch"
@crawl_dir = "/crawl"
@crawldb_dir = "#{@crawl_dir}/crawldb"
@segments_dir = "#{@crawl_dir}/segments"


FIFO::QueueManager.setup(CONFIG[:aws_access_id],CONFIG[:aws_secret_key])
CrawlQueue = FIFO::Queue.new [@env,CONFIG[:queue][:crawl]].join("_")


#############################
# Setup crawl directory
#############################

#puts `hadoop distcp s3n://#{@bucket}/crawl /crawl`
puts `hadoop fs -mkdir /crawl`


#############################
# Launch crawl
#############################

#command = "deploy/bin/nutch crawl "\
#          "s3n://#{@bucket}/#{@name}/urls "\
#          "-depth #{@depth} "\
#          "-topN #{@top_n} "\
#          "-dir /crawl "\
#          "-threads #{@threads}"
#
#puts `#{command}`

inject = "#{@nutch_bin} inject "\
          "#{@crawldb_dir} "\
          "s3n://#{@bucket}/#{@name}/urls"
puts `#{inject}`


(1..@depth).each do |depth|

  generate = "#{@nutch_bin} generate "\
              "#{@crawldb_dir} "\
              "#{@segments_dir} "\
              "-topN #{@top_n}"
  puts `#{generate}`

  segment = `hadoop fs -ls #{@crawl_dir}/segments | tail -1`.split.last

  fetch = "#{@nutch_bin} fetch #{segment} -threads #{@threads}"
  puts `#{fetch}`

  parse = "#{@nutch_bin} parse #{segment}"
  puts `#{parse}`

  update = "#{@nutch_bin} updatedb #{@crawldb_dir} #{segment}"
  puts `#{update}`

end


#############################
# Dump crawled links & html
#############################

command = "deploy/bin/nutch readseg "\
          "-dump /crawl/segments/*  "\
          "/output  "\
          "-nogenerate "\
          "-noparse "\
          "-noparsedata "\
          "-noparsetext "

puts `#{command}`



#############################
# Extract unique products
#############################

puts `hive -f "scripts/hive.sql"`


#############################
# Upload products to s3
#############################

puts `hadoop distcp /hive/products s3n://#{@bucket}/#{@name}/products`


#############################
# Upload crawldb to s3
#############################

#puts `hadoop distcp -overwrite /crawl s3n://#{@bucket}/crawl`
#puts `hadoop distcp /crawl s3n://#{@bucket}/#{@name}/crawl`

#############################
# Finish job
#############################

CrawlQueue.push Object.const_set("Crawler",Class.new),:stop,@job_id,@bucket,@name

