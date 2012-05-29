#!/usr/bin/env ruby

if ARGV.length < 3
  puts "Usage - ruby crawl.rb <environment> <name> <bucket>"
  exit
elsif !["staging","production"].include?(ARGV[0])
  puts "Invalid environment. Valid options - staging,production"
  exit
end

@env = ARGV[0]
@name = ARGV[1]
@bucket = ARGV[2]

puts @env,@name,@bucket


if @env.start_with? "s"
  @depth = 6
  @top_n = 1000
  @threads = 21
else
  @depth = 20
  @top_n = 2000000
  @threads = 21
end


#############################
# Copy crawl db from S3
#############################

puts `hadoop distcp s3n://#{@bucket}/crawl /crawl`



#############################
# Launch crawl
#############################

command = "deploy/bin/nutch crawl "\
          "s3n://#{@bucket}/#{@name}/urls "\
          "-depth #{@depth} "\
          "-topN #{@top_n} "\
          "-dir /crawl "\
          "-threads #{@threads}"

puts `#{command}`



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
# Update crawldb on s3
#############################

puts `hadoop distcp -overwrite /crawl s3n://#{@bucket}/crawl`

