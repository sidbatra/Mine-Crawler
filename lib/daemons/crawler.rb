#!/usr/bin/env ruby


ROOT_PATH = File.dirname(__FILE__) + "/../../"


require 'rubygems'
require 'logger'
require 'aws'
require 'json'
require 'yaml'

require File.join(ROOT_PATH,"external/fifo/lib/fifo.rb")


@logger = Logger.new(File.join(ROOT_PATH,"log/crawler.rb.log"))
@env = ENV['RAILS_ENV']

CONFIG = YAML.load_file(File.join(ROOT_PATH,"config/config.yml"))[@env]

FIFO::QueueManager.setup(CONFIG[:aws_access_id],CONFIG[:aws_secret_key])
ProcessingQueue = FIFO::Queue.new [@env,CONFIG[:queue][:proc]].join("_")
CrawlQueue = FIFO::Queue.new [@env,CONFIG[:queue][:crawl]].join("_")



class Crawler

  def self.start(json)
    stores = JSON.parse json
  end

end



$running = true
Signal.trap("TERM") do 
  $running = false
end

while($running) do
  payload = CrawlQueue.pop

  if payload

    begin
      start_time = Time.now
      payload.process
      end_time = Time.now

      @logger.info "Finished #{payload.to_s} #{end_time - start_time}"

    rescue => ex
      payload.failed

      if payload.attempts < 3
        @logger.info "Recovering #{payload.to_s}"
        payload.queue.push(payload)
      end
    end

  end 
  
  sleep 3
end

