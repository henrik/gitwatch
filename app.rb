require "rubygems"
require "bundler"
require "json"

Bundler.require :default, (ENV['RACK_ENV'] || "development").to_sym

get "/" do
  logger.info "got /"
  "Hello at #{Time.now}"
end

post "/" do
  push = JSON.parse(params[:payload])

  # TODO: What are all these for? Will we get duplicates?
  commits = push["commits"] | [push["head_commit"]]

  logger.info "----------------------------"

  commits.each do |commit|
    touched_paths = commit["modified"] | commit["removed"] | commit["added"]
    commit_url = commit["url"]

    logger.info "URL: #{commit_url.inspect}"
    logger.info "Paths: #{touched_paths.inspect}"

    paths = touched_paths.select { |path| path.include?(".css") }
    if paths.any?
      logger.info "!! CSS gatekeeper: #{commit_url} touched #{paths.inspect}"
    end

    paths = touched_paths.select { |path| path.include?("spec_helper") || path.include?("spec/support") }
    if paths.any?
      logger.info "!! Spec setup nerd: #{commit_url} touched #{paths.inspect}"
    end

    paths = touched_paths.select { |path| path.include?("bovary") }
    if paths.any?
      logger.info "!! Bovarian: #{commit_url} touched #{paths.inspect}"
    end
  end

  "OK!"
end
