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
  def initialize(group_name, people, &matcher)
    @group_name = group_name
    @people = people
    @matcher = matcher
  end

  def matching_paths(paths)
    paths.select(&@matcher)
  end

  attr_reader :group_name, :people
end

class Person < Struct.new(:email, :chat_name)
  @all = []

  def self.all
    @all
  end

  def self.register(email, chat_name)
    person = Person.new(email, chat_name)
    all << person
    person
  end

  def self.find_by_email(email)
    all.find { |person| person.email == email }
  end

  def at_mention
    "@#{chat_name}"
  end
end

$notifiers = []
$notifiers << LogNotifier.new
$notifiers << HipChatNotifier.new(ENV['HIPCHAT_TOKEN'], ENV['HIPCHAT_ROOM_ID'])

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
