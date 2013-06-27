require "bundler"
Bundler.require :default, (ENV['RACK_ENV'] || "development").to_sym

require "json"

require_relative "models/person"
require_relative "models/guard"
require_relative "notifiers/hipchat"
require_relative "notifiers/log"

$notifiers = []
$notifiers << LogNotifier.new
$notifiers << HipChatNotifier.new(ENV['HIPCHAT_TOKEN'], ENV['HIPCHAT_ROOM_ID']) if ENV['HIPCHAT_TOKEN']

henrik = Person.register("henrik@nyh.se", "henrik")
jocke  = Person.register("joakim.kolsjo@gmail.com", "jocke")

$guards = []
$guards << Guard.new("CSS gatekeeper", [henrik]) { |path| path.include?(".css") }
$guards << Guard.new("Spec nerd", [jocke]) { |path| path.include?("spec_helper") }

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

    emails = [ commit["author"]["email"], commit["committer"]["email"] ].compact.uniq
    touchers = emails.map { |email| Person.find_by_email(email) }

    $guards.each do |guard|
      paths = guard.matching_paths(touched_paths)
      people = guard.people - touchers
      group_name = guard.group_name

      if paths.any? && people.any?
        mentions = people.map { |x| x.at_mention }
        notify "#{group_name} (#{list mentions}): #{commit_url} touched #{list paths}"
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

  def list(x)
    x.join(", ")
  end
end
