require 'quikchat'
require 'quikchat/adapter/fake'

RSpec.describe 'messaging with a fake adapter' do

  before do
    QuikChat.configuration.adapter = QuikChat::Adapter::Fake.new
  end

  after do
    QuikChat.configuration.adapter = nil
  end

  it 'quikchats' do
    # send a message for the first time
    quikchat = QuikChat.new(participants: [1,2,3].map{|i| {"id" => i } })
    message = quikchat.post(user_id: 1, body: "hiii").last_message

    # fetch inbox
    conversation = QuikChat.all_for_user_id(1).conversations.first

    # users in conversation
    expect(conversation.user_ids).to eq([1, 2, 3])

    # read conversation
    expect(conversation.messages_with_count(1).messages.first).to eq(message)

    # send a message to the conversation
    new_message = QuikChat.new(id: conversation.id).post(user_id: 2, body: "hi yrself").last_message

    # read conversation again
    expect(conversation.messages_with_count(2, before_time: new_message.created_at).messages).to eq([message])

    # read earlier message count
    expect(conversation.messages_with_count(2, before_time: new_message.created_at).earlier_message_count).to eq(0)

    #find conversation by id
    expect(QuikChat.conversation_by_id_and_user_id(conversation.id, 2).id).to eq(conversation.id)
  end
end
