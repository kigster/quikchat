require 'quikchat'
require 'quikchat/adapter/http'
require 'webmock/rspec'
require 'json'
require 'cgi'

RSpec.describe 'messaging with a http adapter' do

  def expect_http(method, path, request_body: '', response_body: '')
    request_body = JSON.generate(request_body) unless request_body.class == String
    response_body = JSON.generate(response_body) unless response_body.class == String

    request_params = {:headers => {'Accept'=>'application/json'}}
    request_params[:body] = request_body if request_body

    response = {:status => 200, :headers => {"Content-Type" => 'application/json'}}
    response[:body] = response_body if response_body

    stub_request(method, "#{endpoint}/#{path}").with(request_params).to_return(response)
  end

  before do
    WebMock.enable!
    QuikChat.configuration.quikchat_url = endpoint
  end

  after do
    WebMock.disable!
  end

  subject { QuikChat::Adapter::HTTP.new }
  let(:user_id) { 123 }
  let(:before_time) { Time.now }
  let(:before_time_param) { CGI.escape before_time.iso8601(6) }
  let(:endpoint) { 'http://example.com' }

  describe '#conversations' do
    it 'makes the http call to fetch conversations' do
      expect_http(:get, "users/#{user_id}/conversations/1", response_body: {conversations: [], next_page: nil})
      conversations = subject.conversations(user_id)
      expect(conversations["conversations"]).to be_empty
      expect(conversations["next_page"]).to be_nil
    end

    it 'passes the page param' do
      page = 2
      expect_http(:get, "users/#{user_id}/conversations/#{page}", response_body: {conversations: [], next_page: nil})
      conversations = subject.conversations(user_id, page)
      expect(conversations["conversations"]).to be_empty
    end
  end

  describe '#with_user_ids' do
    it 'makes the http call to create conversation' do
      expect_http(:post, "conversations",
                  request_body: {user_ids: [user_id]},
                  response_body: {conversations: [{id: 1}] })
      conversation = subject.with_user_ids([user_id])
      expect(conversation).to eq({ 'id' => 1 })
    end
  end

  describe '#post' do
    it 'makes the http call to post a message' do
      expect_http(:post, "conversations/#{user_id}/messages",
        request_body: {user_id: 123, message: {user_id: 123, body: 'Hoopy Frood', subject_type:'', subject_id: ''}},
        response_body: {conversations: [{last_message: {body: 'Hoopy Frood'}}]})
      subject.post(user_id, user_id, 'Hoopy Frood', '', '')
    end
  end

  describe '#messages' do
    it 'makes http call to get messages' do
      cid = 1
      expect_http(:get, "conversations/#{cid}/messages?user_id=#{user_id}", response_body: {messages: 'omergerd', earlier_message_count: 1})
      messages = subject.messages(cid, user_id)
      expect(messages).to eq({'messages' => 'omergerd', 'earlier_message_count' => 1})
    end

    it 'passes before_time' do
      cid = 1
      expect_http(:get, "conversations/#{cid}/messages?user_id=#{user_id}&before_time=#{before_time_param}", response_body: {messages: 'omergerd', earlier_message_count: 1})
      messages = subject.messages(cid, user_id, before_time)
      expect(messages).to eq({'messages' => 'omergerd', 'earlier_message_count' => 1})
    end
  end

  describe '#mark_read!' do
    it 'marks the conversation as read' do
      cid = "321"
      expect_http(:post, "conversations/#{cid}/mark_as_read", request_body: {user_id: user_id}, response_body: {})
      subject.mark_read!(cid, user_id)
    end
  end

  describe '#conversation_by_id_and_user_id' do
    it 'makes http call to get conversation' do
      id = 1
      expect_http(:get, "conversations/#{id}?user_id=#{user_id}", response_body: {conversation: {id: id}})
      response = subject.conversation_by_id_and_user_id(id, user_id)
      expect(response).to eq({"id" => id})
    end
  end

  describe '#unread_conversation_count' do
    it 'makes http call to get unread conversation count' do
      expect_http(:get, "users/#{user_id}/unread_conversation_count", response_body: {unread_count: 2})
      expect(subject.unread_conversation_count_for_user_id(user_id)).to eq(2)
    end

    context 'if an exception occures' do
      let(:exception) { Exception.new }
      before do
        expect(HTTParty).to receive(:get).and_raise(exception)
      end

      it 'returns 0' do
        expect(subject.unread_conversation_count_for_user_id(user_id)).to eq(0)
      end

      it 'calls error delegate' do
        error_delegate = double('error_delegate', notice_error: :nil)
        expect(error_delegate).to receive(:notice_error).with(exception, custom_params: {user_id: user_id})
        subject.error_delegate = error_delegate
        subject.unread_conversation_count_for_user_id(user_id)
      end

      it 'does not call error delegate does not respond to notice error' do
        error_delegate = 'I am a simple string'
        subject.error_delegate = error_delegate
        subject.unread_conversation_count_for_user_id(user_id)
      end
    end
  end
end
