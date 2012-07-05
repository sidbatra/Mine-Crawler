#!/usr/bin/env ruby


ROOT_PATH = File.dirname(__FILE__) + "/../../"


require 'rubygems'
require 'json'
require 'logger'

@logger = Logger.new(File.join(ROOT_PATH,"log/crawler.rb.log"))


class Crawler

  def self.start(json)
    stores = JSON.parse json
  end
end


$running = true
Signal.trap("TERM") do 
  $running = false
end

puts "hello"
#while($running) do
#  payload = CrawlQueue.pop
#
#  if payload
#
#    begin
#      start_time = Time.now
#      payload.process
#      end_time = Time.now
#
#      @logger.info "Finished #{payload.to_s} #{end_time - start_time}"
#
#    rescue => ex
#      payload.failed
#
#      if payload.attempts < 3
#        @logger.info "Recovering #{payload.to_s}"
#        payload.queue.push(payload)
#      end
#    end
#
#  end 
#  
#  sleep 3
#end

