#!/usr/bin/env ruby


ROOT_PATH = File.dirname(__FILE__) + "/../../"


require 'rubygems'
require 'logger'
require 'aws'
require 'json'
require 'yaml'

require File.join(ROOT_PATH,"external/fifo/lib/fifo.rb")


LOGGER = Logger.new(File.join(ROOT_PATH,"log/crawler.rb.log"))
@env = ENV['RAILS_ENV']

CONFIG = YAML.load_file(File.join(ROOT_PATH,"config/config.yml"))[@env]

FIFO::QueueManager.setup(CONFIG[:aws_access_id],CONFIG[:aws_secret_key])
ProcessingQueue = FIFO::Queue.new [@env,CONFIG[:queue][:proc]].join("_")
CrawlQueue = FIFO::Queue.new [@env,CONFIG[:queue][:crawl]].join("_")



# Crawler class is an endpoint for public methods
# accessible via the CrawlQueue.
#
class Crawler

  # Launch a new crawl job for the given stores.
  #
  def self.start(json)
    name = Time.now.to_i.to_s
    base_path = File.join(ROOT_PATH,"data/#{name}")
    urls_path = File.join(base_path,"urls.txt")
    hash_path = File.join(base_path,"hash.txt")
    stores = JSON.parse json

    Dir.mkdir base_path

    urls_file = File.open(urls_path,'w')
    hash_file = File.open(hash_path,'w')

    stores.each do |store|
      urls_file.puts "#{store['launch_url']}\tnutch.score=20"
      hash_file.puts store.to_json
    end

    urls_file.close
    hash_file.close

    command = "cd #{ROOT_PATH} && ruby scripts/automation.rb "\
              "#{ENV['RAILS_ENV']} #{urls_path} #{hash_path} #{name}"

    LOGGER.info `#{command}`
  end

  # Terminate an existing crawl.
  #
  def self.stop(job_id,bucket,name)
    command = "cd #{ROOT_PATH} && ./elastic-mapreduce/elastic-mapreduce "\
              "--terminate #{job_id}"
    LOGGER.info `#{command}`

    ProcessingQueue.push Object.const_set("Product",Class.new),
                      :import_crawled,
                      bucket,
                      "#{name}/products"
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

      LOGGER.info "Finished #{payload.to_s} #{end_time - start_time}"

    rescue => ex
      payload.failed

      if payload.attempts < 3
        LOGGER.info "Recovering #{payload.to_s}"
        payload.queue.push(payload)
      else
        LOGGER.info "#{ex.message}\n#{ex.backtrace}"
      end
    end

  end 
  
  sleep 3
end

