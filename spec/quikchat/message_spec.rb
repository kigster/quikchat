require 'quikchat/message'

RSpec.describe QuikChat::Message do
  let(:message) { QuikChat::Message.new(
      id: 1,
      user_id: 2,
      conversation_id: 3,
      body: "hi",
      subject_type: "Product",
      subject_id: 4,
  )}

  describe '#body' do
    it 'returns the body' do
      expect(message.body).to eq("hi")
    end
  end

  describe '#subject_id' do
    it 'returns the id of the subject' do
      expect(message.subject_id).to eq(4)
    end
  end

  describe '#subject_type' do
    it 'returns the class name of the subject' do
      expect(message.subject_type).to eq('Product')
    end
  end

  describe '#user_id' do
    it 'returns the user_id' do
      expect(message.user_id).to eq(2)
    end
  end
end
