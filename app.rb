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

    client = HipChat::Client.new(@api_token)
    client[@room_id].send("gitwatch", message, message_format: "text")
  end
end

class LogNotifier
  def notify(context, message)
    context.logger.info message
  end
end

class Guard
  def initialize(group, nicks, &matcher)
    @group = group
    @nicks = nicks
    @matcher = matcher
  end

  def matching_paths(paths)
    paths.select(&@matcher)
  end

  attr_reader :group, :nicks
end

$notifiers = []
$notifiers << LogNotifier.new
$notifiers << HipChatNotifier.new(ENV['HIPCHAT_TOKEN'], ENV['HIPCHAT_ROOM_ID'])

$guards = []
$guards << Guard.new("CSS gatekeeper", %w[henrik]) { |path| path.include?(".css") }
$guards << Guard.new("Spec nerd", %w[jocke]) { |path| path.include?("spec_helper") || path.include?("spec/support") || path.include?("unit/support") }

get "/" do
  "Hello!"
end

post "/" do
  push = JSON.parse(params[:payload])

  # TODO: What are all these for? Will we get duplicates?
  commits = push["commits"] | [push["head_commit"]]

  commits.each do |commit|
    touched_paths = commit["modified"] | commit["removed"] | commit["added"]
    commit_url = commit["url"]

    $guards.each do |guard|
      paths = guard.matching_paths(touched_paths)
      if paths.any?
        mentions = guard.nicks.map { |x| "@#{x}" }.join(", ")
        notify "#{guard.group} (#{mentions}): #{commit_url} touched #{paths.join(", ")}"
      end
    end
  end

  "OK!"
end

helpers do
  def notify(message)
    $notifiers.each do |notifier|
      notifier.notify(self, message)
    end
  end
end
