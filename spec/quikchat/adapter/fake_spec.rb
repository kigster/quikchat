require 'quikchat'
require 'quikchat/adapter/fake'
require 'json'

RSpec.describe 'messaging with a fake adapter' do

  def debug_conversations
    subject.instance_variable_get(:@conversations)
  end

  subject { QuikChat::Adapter::Fake.new }
  let(:user_id) { 123 }

  describe '#conversations' do
    it 'returns existing conversations' do
      conversations = subject.conversations(user_id)
      expect(conversations["conversations"]).to match_array []
    end

    context 'with conversations' do
      let!(:conversation1) { subject.with_user_ids([user_id]) }
      let!(:conversation2) { subject.with_user_ids([user_id, 1, 2]) }
      let!(:conversation3) { subject.with_user_ids([user_id, 1, 2, 3]) }

      it 'returns existing conversations' do
        conversations = subject.conversations(user_id)
        expect(conversations["conversations"]).to match_array [conversation1, conversation2, conversation3]
      end

      it 'passes the page' do
        stub_const("QuikChat::Adapter::Fake::PAGE_SIZE", 1)
        conversations = subject.conversations(user_id, 2)
        expect(conversations["conversations"]).to match_array [conversation2]
      end

      it 'returns empty if page number exceeds total page number' do
        stub_const("QuikChat::Adapter::Fake::PAGE_SIZE", 1)
        conversations = subject.conversations(user_id, 5)
        expect(conversations["conversations"]).to be_empty
      end
    end
  end

  describe '#active_conversation' do
    it 'returns the last conversation that the user posted in' do
      c1 = subject.with_user_ids([user_id, 1])
      subject.post(c1['id'], user_id, 'woo')
      c1 = subject.with_user_ids([user_id, 1])
      expect(subject.active_conversation(user_id)).to eq(c1)
    end
  end

  describe '#with_user_ids' do
    it 'creates a conversation' do
      conversation = subject.with_user_ids([user_id])
      expect(conversation['id']).to eq 1
      expect(conversation['participants']).to eq [{'id' => user_id}]
    end
  end

  describe '#post' do
    it 'returns a collection with the new message' do
      conversation = subject.with_user_ids([user_id])
      updated_conversation = subject.post(conversation['id'], user_id, 'Hoopy Frood')

      expect(updated_conversation).to eq(subject.with_user_ids([user_id]))

      message = updated_conversation['last_message']
      expect(message['id']).to eq 1
      expect(message['conversation_id']).to eq conversation['id']
      expect(message['body']).to eq 'Hoopy Frood'
      expect(message['subject_type']).to eq nil
      expect(message['subject_id']).to eq nil
    end
  end

  describe '#messages' do
    it 'gets messages and earlier message count' do
      conversation = subject.with_user_ids([user_id])
      expect(subject.messages(conversation['id'], user_id)['messages']).to eq []
      expect(subject.messages(conversation['id'], user_id)['earlier_message_count']).to eq 0
    end

    context 'before_time is given' do
      it 'returns messages created before given time' do
        conversation = subject.with_user_ids([user_id])

        message1 = subject.post(conversation['id'], user_id, 'VIM')['last_message']
        message2 = subject.post(conversation['id'], user_id, 'EMACS')['last_message']

        expect(subject.messages(conversation['id'], user_id)['messages']).to match_array [message1, message2]
        expect(subject.messages(conversation['id'], user_id, message2['created_at'])['messages']).to match_array [message1]
      end

      it 'returns earlier_message_count correctly' do
        stub_const("QuikChat::Adapter::Fake::PAGE_SIZE", 1)

        conversation = subject.with_user_ids([user_id])

        message1 = subject.post(conversation['id'], user_id, 'VIM')['last_message']
        message2 = subject.post(conversation['id'], user_id, 'EMACS')['last_message']
        message3 = subject.post(conversation['id'], user_id, 'APPCODE')['last_message']

        expect(subject.messages(conversation['id'], user_id, message3['created_at'])['earlier_message_count']).to eq 1
      end
    end

    context 'before time is not given' do

      it 'marks conversation as read' do
        conversation = subject.with_user_ids([user_id])
        subject.post(conversation['id'], user_id, 'VIM')
        expect {
          subject.messages(conversation['id'], user_id)
        }.to change { subject.with_user_ids([user_id])["participants"].find{|p| p["id"] == user_id }["last_read_at"] }
      end

    end
  end

  describe '#mark_read!' do
    it 'marks the conversation as read' do
      conversation = subject.with_user_ids([user_id])
      expect {
        subject.mark_read!(conversation["id"], user_id)
      }.to change { subject.with_user_ids([user_id])["participants"].find{|p| p["id"] == user_id }["last_read_at"] }
    end
  end

  describe '#unread_conversation_count_for_user_id' do
    it 'returns unread count' do
      conversation = subject.with_user_ids([1, 2])
      subject.post(conversation['id'], 2, 'APPCODE')

      expect(subject.unread_conversation_count_for_user_id(1)).to eq 1
    end
  end
end
