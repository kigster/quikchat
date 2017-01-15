require 'quikchat/version'
require 'quikchat/configuration'
require 'quikchat/message'
require 'quikchat/messages_response'
require 'quikchat/conversations_response'

class QuikChat
  class RecordNotFound < RuntimeError; end

  ATTRS = :id, :created_at, :updated_at, :last_message, :participants
  attr_reader(*ATTRS)

  def self.configuration
    @configuration ||= QuikChat::Configuration.new
    yield @configuration if block_given?
    @configuration
  end

  def self.all_for_user_id(user_id, page = 1)
    response = configuration.adapter.conversations(user_id, page)
    conversations = response['conversations'].map{|c| new c }
    ConversationsResponse.new(conversations: conversations, next_page: response['next_page'])
  end

  def self.active_for_user_id(user_id)
    convo = configuration.adapter.active_conversation(user_id)
    convo.blank? ? nil : new(convo)
  end

  def self.conversation_by_id_and_user_id(id, user_id)
    new configuration.adapter.conversation_by_id_and_user_id(id, user_id)
  end

  def self.unread_conversation_count_for_user_id(user_id)
    configuration.adapter.unread_conversation_count_for_user_id(user_id)
  end

  def initialize(args)
    update_attributes({id: nil}.merge(args))
    raise ArgumentError, "id or participants is required" if id.nil? && (participants.nil? || participants.empty?)
  end

  def post(user_id:, body:, subject_type: nil, subject_id: nil)
    ensure_created!
    result = adapter.post(id, user_id, body, subject_type, subject_id)
    update_attributes(result)
  end

  def messages_with_count(user_id, before_time: nil)
    return MessagesResponse.new if id.nil?
    response = adapter.messages(id, user_id, before_time)
    MessagesResponse.new(earlier_message_count: response['earlier_message_count'], messages: response['messages'].map {|m| Message.new m}, unread_conversation_count: response['unread_conversation_count'])
  end

  def mark_read!(user_id)
    adapter.mark_read!(id, user_id)
  end

  def user_ids
    participants.map{|p| p["id"] || p[:id] }
  end

  def is_unread_for_participant?(participant_id)
    unread = false
    participants.each do |p|
      if p["id"] == participant_id && (p['last_read_at'] == nil || p['last_read_at'] < updated_at)
        unread = true
        break
      end
    end
    unread
  end

protected

  attr_writer(*ATTRS)

  def last_message=(attrs)
    @last_message = Message.new(attrs)
  end

  def participants=(participants)
    @participants = participants.map do |p|
      Hash[p.map{|k,v| [k.to_s, v] }]
    end
  end

  def update_attributes(attrs)
    attrs.each { |key, value| send("#{key}=", value) if value }
    self
  end

  def ==(other)
    self.id == other.id
  end

  def ensure_created!
    return if @id
    created_data = adapter.with_user_ids(user_ids)
    @id, @created_at, @updated_at = created_data.values_at("id", "created_at", "updated_at")
  end

  def adapter
    self.class.configuration.adapter
  end
end
