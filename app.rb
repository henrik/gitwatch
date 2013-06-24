require "rubygems"
require "bundler"
require "json"

Bundler.require :default, (ENV['RACK_ENV'] || "development").to_sym

get "/" do
  "Hello at #{Time.now}"
  logger.info "got /"
end

post "/" do
  push = JSON.parse(params[:payload])

  # TODO: What are all these for? Will we get duplicates?
  commits = push[:commits] | [push[:head_commit]]

  commits.each do |commit|
    touched_paths = commit[:modified] | commit[:removed] | commit[:added]

    logger.info "URL: #{commit[:url].inspect}"
    logger.info "Paths: #{touched_paths.inspect}"
  end
end
