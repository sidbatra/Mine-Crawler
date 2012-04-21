#!/usr/bin/ruby

images = {}

STDIN.each_line do |line|
  url,title,image,store_id,description=line.split("\t")

  begin

  ##
  # Test if input is proper.
  ##
  next if url.nil? || url.length.zero? || image.nil? || image.length.zero?


  unless images.key? image
    puts [url,title,image,store_id,description].join("\t")
    images[image] = true
  end

  rescue => ex
    $stderr.puts "Error with processing unique url - #{url} : #{ex.message}"
  end

end
