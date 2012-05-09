#!/usr/bin/env ruby

require 'rubygems'
require 'aws/s3'


if ARGV.length < 2
  puts "Usage - ruby download.rb <name> <bucket>"
  exit
end

@name = ARGV[0]
@bucket = ARGV[1]

puts @name,@bucket


Dir.mkdir(@name) unless File.directory?(@name)
Dir.mkdir("#{@name}/products") unless File.directory?("#{@name}/products")


AWS::S3::Base.establish_connection!(
  :access_key_id     => "AKIAJWYCAWDPAAKLNKSQ",
  :secret_access_key => "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")

AWS::S3::Bucket.objects(@bucket,:prefix => "#{@name}/products").each do |object|
  next if object.key.match("\\$folder\\$")
  puts object.key
  File.open("#{object.key}",'w'){|f| f.write object.value}
end
