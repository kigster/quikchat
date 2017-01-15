require 'quikchat'

RSpec.describe QuikChat do

  describe '.configuration' do
    before do
      QuikChat.configuration.adapter = double("adapter")
    end

    it 'returns an instance of the configuration' do
      expect(QuikChat.configuration).to be_a(QuikChat::Configuration)
    end

    it 'yields a configuration' do
      expect { |b|
        QuikChat.configuration(&b)
      }.to yield_with_args(instance_of(QuikChat::Configuration))
    end
  end

  describe '.all_for_user_id' do
    it 'returns conversations for a given user from the adapter' do
      expect(adapter).to receive(:conversations).
        with(1, 1).and_return({"conversations" => [{id: 1}, {id: 2}], "next_page" => nil}).once
      expect(QuikChat.all_for_user_id(1).conversations).to eq([QuikChat.new(id: 1), QuikChat.new(id: 2)])
    end
  end

  let(:adapter) do
    double("adapter").tap do |adapter|
      allow(QuikChat.configuration).to receive(:adapter).and_return(adapter)
    end
  end

  describe '#initialize' do
    describe 'conversation has empty last_message' do
      let(:conversation) {
        {
          "id" => 46,
          "last_message" => nil,
          "participants" => [
            {"id" => 1, "last_read_at" => nil},
            {"id" => 2, "last_read_at" => nil},
          ],
          "updated_at" => "2014-07-31T20:26:35.482Z"}
      }

      it 'does not blow up' do
        QuikChat.new(conversation)
      end
    end
  end

  describe '#post with an id' do
    it 'posts the message' do
      expect(adapter).to receive(:post).with(1, 2, "hi", "Product", 3).
        and_return({"last_message" => {id: 1, user_id: 2, body: "hi", subject_type: "Product", subject_id: 3}})
      conversation = QuikChat.new(id: 1)
      conversation.post(user_id: 2, body: "hi", subject_type: "Product", subject_id: 3)
      msg = conversation.last_message

      expect(msg).to be_a(QuikChat::Message)
      expect(msg.body).to eq("hi")
      expect(conversation.last_message).to eq(msg)
    end
  end

  describe '#post without an id' do
    it 'posts the message' do
      expect(adapter).to receive(:with_user_ids).with([1,2,3]).and_return("id" => 1, "created_at" => Time.now)
      expect(adapter).to receive(:post).with(1, 2, "hi", "Product", 3).
        and_return({participants: [{id: 1}, {id: 2}, {id: 3}], last_message: {id: 1, user_id: 2, body: "hi", subject_type: "Product", subject_id: 3}})
      conversation = QuikChat.new(participants: [{id: 1},{id: 2}, {id: 3}])
      conversation.post(user_id: 2, body: "hi", subject_type: "Product", subject_id: 3)
      msg = conversation.last_message

      expect(msg).to be_a(QuikChat::Message)
      expect(msg.body).to eq("hi")
      expect(conversation.last_message).to eq(msg)
      expect(conversation.created_at).to be_within(1).of(Time.now)
    end
  end

  describe '#messages' do
    it 'lists messages' do
      expect(adapter).to receive(:messages).with(1, 2, nil).and_return({'messages' => [{id: 1},{id: 2},{id: 3}]}).once
      expect(QuikChat.new(id: 1).messages_with_count(2).messages).to eq((1..3).map{|i| QuikChat::Message.new(id: i) })
    end

    it 'returns earlier message count' do
      earlier_message_count = 5
      expect(adapter).to receive(:messages).with(1, 2, nil).and_return({'earlier_message_count' => earlier_message_count, 'messages' => []}).once
      expect(QuikChat.new(id: 1).messages_with_count(2).earlier_message_count).to eq(earlier_message_count)
    end
  end

  describe '#last_message' do
    it 'returns the last message' do
      quikchat = QuikChat.new(id: 1, participants: [{id: 2}, {id: 3}], last_message: {id: 1, body: "hi"})
      expect(quikchat.last_message.body).to eq("hi")
    end
  end

  describe '#mark_read!' do
    it 'marks conversation as read' do
      quikchat = QuikChat.new(id: 1, participants: [{id: 2}, {id: 3}], last_message: {id: 1, body: "hi"})
      expect(adapter).to receive(:mark_read!).with(1, 2)
      quikchat.mark_read!(2)
    end
  end

  describe '#is_unread_for_participant?' do

    let(:time) { Time.now }

    let(:quikchat) {
      QuikChat.new(
        'id' => 1,
        'participants' => [
          {'id' => 2, 'last_read_at' => time - 3},
          {'id' => 3, 'last_read_at' => time - 1},
          {'id' => 4, 'last_read_at' => nil}
        ],
        'last_message' => {
          'id' => 1,
          'body' => "hi"
        },
        'updated_at' => time - 2)
    }

    it 'returns true if there is an unread message' do
      expect(quikchat.is_unread_for_participant?(2)).to be(true)
    end

    it 'returns false if all the messages are read' do
      expect(quikchat.is_unread_for_participant?(3)).to be(false)
    end

    it 'returns true if last_read_at is nil' do
      expect(quikchat.is_unread_for_participant?(4)).to be(true)
    end

  end

  describe '.conversation_by_id_and_user_id' do
    it 'returns conversation with given id' do
      expect(adapter).to receive(:conversation_by_id_and_user_id).with(1, 2).and_return({"id" => 1})
      conversation = QuikChat.conversation_by_id_and_user_id(1, 2)
      expect(conversation.id).to eql(1)
    end
  end
end
