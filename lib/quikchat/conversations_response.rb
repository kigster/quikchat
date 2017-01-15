class ConversationsResponse
  attr_reader :conversations, :next_page

  def initialize(conversations: [], next_page: nil)
    @conversations = conversations
    @next_page = next_page
  end
end
