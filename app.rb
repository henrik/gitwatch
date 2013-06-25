require "bundler"
require "json"

Bundler.require :default, (ENV['RACK_ENV'] || "development").to_sym

class HipChatNotifier
  def initialize(api_token, room_id)
    @api_token = api_token
    @room_id = room_id
  end

  def notify(context, message)
    unless @api_token
      context.logger.info "No HipChat token!"
      return
    end

    HipChat::Client.new(@api_token)
    client[@room_id].send("gitwatch", message)
  end
end

class LogNotifier
  def notify(context, message)
    context.logger.info message
  end
end

$notifiers = [
  LogNotifier.new,
  HipChatNotifier.new(ENV['HIPCHAT_TOKEN'], ENV['HIPCHAT_ROOM_ID'])
]

get "/" do
  logger.info "got /"
  "Hello at #{Time.now}"
end

post "/" do
  push = JSON.parse(params[:payload])

  # TODO: What are all these for? Will we get duplicates?
  commits = push["commits"] | [push["head_commit"]]

  log "----------------------------"

  commits.each do |commit|
    touched_paths = commit["modified"] | commit["removed"] | commit["added"]
    commit_url = commit["url"]

    log "URL: #{commit_url.inspect}"
    log "Paths: #{touched_paths.inspect}"

    paths = touched_paths.select { |path| path.include?(".css") }
    if paths.any?
      log "!! CSS gatekeeper: #{commit_url} touched #{paths.inspect}"
    end

    paths = touched_paths.select { |path| path.include?("spec_helper") || path.include?("spec/support") }
    if paths.any?
      log "!! Spec setup nerd: #{commit_url} touched #{paths.inspect}"
    end

    paths = touched_paths.select { |path| path.include?("bovary") }
    if paths.any?
      log "!! Bovarian: #{commit_url} touched #{paths.inspect}"
    end
  end

  "OK!"
end

helpers do
  def log(message)
    $notifiers.each do |notifier|
      notifier.notify(self, message)
    end
  end
end
