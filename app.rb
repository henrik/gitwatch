require "rubygems"
require "bundler"
Bundler.require :default, (ENV['RACK_ENV'] || "development").to_sym

get "/" do
  "Hello at #{Time.now}"
end
