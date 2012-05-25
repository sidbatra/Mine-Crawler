#!/usr/bin/ruby

require 'rubygems'
require 'nokogiri'
require 'fastimage'

stores_file = "/home/hadoop/hash.txt"

# Debugging inputs.
#url = "http://www.jcrew.com/AST/Navigation/Shoes/men/PRDOVR~28357/28357.jsp"
#html =`cat data`
#stores_file = "data/hash.txt"


STORES = {}
File.open(stores_file,'r') do |file|
  file.each do |line|
    domain,id = line.chomp.split "\t"
    STORES[domain] = id.to_i
  end
end



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
  store_id = 0


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
  # Extract og product image.
  ##
  doc.xpath("//meta[@property='og:image']/@content").each do |node|
    og_image = node.value 
    next if og_image.nil?

    begin
      size = FastImage.size(og_image)
      image = og_image if size[0] > 149 && size[1] > 149
    rescue => ex
      $stderr.puts "Error fetching size of og img - #{og_image} : #{ex.message}"
    end
  end

  ##
  # Extract product images from html.
  ##
  if image.length.zero?
    doc.xpath("//img").each do |img|
      src = img['src']
      next if src.nil? || src.length.zero?

      begin
        images << (src.match(/^http/) ? 
                    src : 
                    URI.decode(uri.merge(URI.encode(src)).to_s).gsub("¥","\\"))
      rescue => ex
        $stderr.puts "Error parsing image src - #{src} : #{ex.message}"
      end
    end

    ##
    # Extract best product image.
    ##
    images.each do |img|
      begin
        size = FastImage.size(img)
        aspectRatio = size[0] / (size[1] + 0.0)
      rescue => ex
        $stderr.puts "Error fetching size of img - #{img} : #{ex.message}"
      end

      if size && size[0] > 149 && size[1] > 149 && 
          size[0] > image_size[0] && size[1] > image_size[1] &&
          aspectRatio < 3 && aspectRatio > 0.3
        image = img 
        image_size = size
      end
    end
  end #if image length zero


  ##
  # Extract store id.
  ##
  STORES.each do |domain,id|
    if url.match(domain) 
      store_id = id 
      break
    end
  end

  ##
  # Final test of output.
  ##
  next if title.length.zero? || image.length.zero? || store_id.zero?

  puts [url,title,image,store_id,description].join("\t")

  rescue => ex
    $stderr.puts "Error with url - #{url} : #{ex.message}"
  end

end
