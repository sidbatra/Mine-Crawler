#!/usr/bin/env ruby

require 'rubygems'
require 'aws/s3'


if ARGV.length < 3
  puts "Usage - ruby initialize.rb <s3 bucket> <boostrap path> <seed path>"
end

bucket = ARGV[0]
bootstrap_path = ARGV[1]
seed_path = ARGV[2]


AWS::S3::Base.establish_connection!(
  :access_key_id     => "AKIAJWYCAWDPAAKLNKSQ",
  :secret_access_key => "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")

AWS::S3::S3Object.store(
  bootstrap_path,
  "script/

