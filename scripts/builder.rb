#!/usr/bin/env ruby

if ARGV.length < 1
  puts "Usage - ruby builder.rb <dataset path> <product url>"
  exit
end

require 'rubygems'
require 'mechanize'
require 'open-uri'

#@dataset_path = ARGV[0]
@product_url = ARGV[0]

@dataset_path = "data/pages/#{URI.parse(URI.encode(@product_url)).host}.txt"

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
