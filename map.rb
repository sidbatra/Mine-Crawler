#!/usr/bin/ruby

require 'rubygems'
require 'nokogiri'
require 'fastimage'

#STDIN.each_line do |line|
#  url,html=line.split("\t")
#
#  next unless url && url.length && html && html.length
#  puts url if(html.match("og:title"))
#end

data =`cat data`
doc = Nokogiri::HTML(data)

doc.xpath("//meta[@property='og:title']/@content").each do |node|
  puts node.value
end
#puts doc.css("meta[property='og:title']").first.attributes['content'].value

doc.xpath("//meta[@property='og:image']/@content").each do |node|
  puts node.value
end
#puts doc.css("meta[property='og:image']").first.attributes['content'].value

doc.xpath("//title").each do |node|
  puts node.children.text
end
#puts doc.css('title').children.text




puts "\n\nIMAGES \n"

#TODO: Multi thread
#
doc.xpath("//img").each do |img|
  p img['src'], FastImage.size(img['src'])
end
#doc.css("img").each do |img|
#  puts img['src']#, FastImage.size(img['src'])
#end


