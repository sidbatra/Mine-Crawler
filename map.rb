#!/usr/bin/ruby

require 'rubygems'
require 'nokogiri'
require 'fastimage'

# Debugging inputs.
#url = "http://www.jcrew.com/AST/Navigation/Shoes/men/PRDOVR~28357/28357.jsp"
#html =`cat data`


STDIN.each_line do |line|
  url,html=line.split("\t")

  begin

  ##
  # Test if input is proper.
  ##
  next if url.nil? || url.length.zero? || html.nil? || html.length.zero?

  ##
  # Initialize.
  ##
  uri = URI.parse(URI.encode(url))
  title = ""
  description = ""
  images = []
  image = ""
  image_size = [0,0]


  ##
  # Test if the html contains a product.
  ##
  next unless html.match("og:title")


  ##
  # Parse html.
  ##
  doc = Nokogiri::HTML(html)
  next if doc.nil?


  ##
  # Extract product title.
  ##
  doc.xpath("//meta[@property='og:title']/@content").each do |node|
    title = node.value if node.value
  end

  doc.xpath("//title").each do |node|
    title = node.children.text if node.children && node.children.text
  end if title.length.zero?

  doc.xpath("//meta[@name='title']/@content").each do |node|
    title = node.value if node.value
  end if title.length.zero?


  ##
  # Extract product description.
  ##
  doc.xpath("//meta[@property='og:description']/@content").each do |node|
    description = node.value if node.value
  end

  doc.xpath("//meta[@name='description']/@content").each do |node|
    description = node.value if node.value
  end if description.length.zero?


  ##
  # Extract potential product images.
  ##
  doc.xpath("//meta[@property='og:image']/@content").each do |node|
    images << node.value if node.value
  end

  doc.xpath("//img").each do |img|
    src = img['src']
    next if src.nil? || src.length.zero?

    begin
      images << (src.match(/^http/) ? 
                  src : 
                  URI.decode(uri.merge(URI.encode(src)).to_s).gsub("¥","\\"))
    rescue
      $stderr.puts "Error parsing image src - #{src}"
    end
  end

  ##
  # Extract best product image.
  ##
  images.each do |img|
    begin
      size = FastImage.size(img)
    rescue
      $stderr.puts "Error fetching size of img - #{img}"
    end

    if size && size[0] > image_size[0] && size[1] > image_size[1]
      image = img 
      image_size = size
    end
  end

  puts [url,title,description,image].join("\t")

  rescue
    $stderr.puts "Error with url - #{url}"
  end

end
