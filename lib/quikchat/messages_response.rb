class MessagesResponse
  attr_reader :earlier_message_count, :messages, :unread_conversation_count

  def initialize(earlier_message_count: 0, messages: [], unread_conversation_count: nil)
    @earlier_message_count = earlier_message_count
    @messages = messages
    @unread_conversation_count = unread_conversation_count
  end
end
