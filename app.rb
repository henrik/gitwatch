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
  logger.info "I got some JSON: #{push.inspect}"
end
