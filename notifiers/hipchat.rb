class HipChatNotifier
  def initialize(api_token, room_id)
    @api_token = api_token
    @room_id = room_id
  end

  def notify(context, message)
    client = HipChat::Client.new(@api_token)
    client[@room_id].send("gitwatch", message, message_format: "text")
  end
end
