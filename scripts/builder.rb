#!/usr/bin/env ruby

if ARGV.length < 2
  puts "Usage - ruby builder.rb <dataset path> <product url>"
  exit
end

require 'rubygems'
require 'mechanize'

@dataset_path = ARGV[0]
@product_url = ARGV[1]

puts @dataset_path,@product_url,"\n"



agent = Mechanize.new
body = agent.get(@product_url).body

if body.match "og:title"
  puts "Webpage OG compatible"

  File.open(@dataset_path,"a") do |file|
    file.puts @product_url + "\t" + body.gsub(/(\r|\n|\t)/," ")
  end
else
  puts "No OG tags found"
  exit
end
