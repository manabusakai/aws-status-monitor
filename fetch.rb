#!/usr/bin/env ruby

require 'rss'

def get_rss_url(region, service)
  base_url = 'http://status.aws.amazon.com/rss/'
  return base_url + service + '-' + region + '.rss'
end

def get_log_dir
  log_dir = Dir.pwd + '/log/'
  Dir.mkdir(log_dir) unless File.exist?(log_dir)
  return log_dir
end

def get_log_file(service)
  return get_log_dir + service + '.log'
end

def set_guid(service, guid)
  File.open(get_log_file(service), 'w') do |f|
    f.write(guid)
  end
end

# TODO
region   = 'ap-northeast-1'
services = ['ec2', 'elb', 'rds', 's3', 'gamelift']

services.each do |service|
  rss = RSS::Parser.parse(get_rss_url(region, service), false)
  next if rss.items.empty?

  # Create a file only the first time.
  guid = rss.items[0].guid.content
  unless File.exist?(get_log_file(service))
    set_guid(service, guid)
    next
  end

  is_update = false
  prev_guid = File.open(get_log_file(service)).gets.chomp

  rss.items.each do |item|
    next_guid = item.guid.content
    break if next_guid == prev_guid

    is_update = true
    puts "[#{service.upcase}] #{item.pubDate} : #{item.title}"
  end

  # Record a new guid.
  set_guid(service, guid) if is_update

  # Random delay.
  sleep rand(1..7)
end
