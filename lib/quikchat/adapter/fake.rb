class QuikChat
  module Adapter
    class Fake

      PAGE_SIZE = 100

      def initialize
        @conversations = []
        @messages = Hash.new{|h,k| h[k] = [] }
        @active_conversation = {}
      end

      def conversations(user_id, page = 1)
        return {"conversations" => [], "next_page" => nil} if @conversations.empty?
        user_id = user_id.to_i unless user_id.nil?
        sorted_conversations = @conversations.
          select { |c| c["participants"].map { |p| p['id'] }.include?(user_id) }.
          sort { |x, y| y["updated_at"] <=> x["updated_at"] }

        start_idx = (page - 1) * PAGE_SIZE
        conversations_in_page = sorted_conversations[start_idx..start_idx+PAGE_SIZE-1] || []
        next_page = conversations_in_page.count == PAGE_SIZE ? page + 1 : nil
        {"conversations" => conversations_in_page, "next_page" => next_page}
      end

      def active_conversation(user_id)
        conversation = @active_conversation[user_id.to_i]
        conversation == nil ? nil : conversation.dup
      end

      def with_user_ids(user_ids)
        user_ids.map!(&:to_i)

        c = @conversations.find{|c| c["participants"].map{|p| p["id"] } == user_ids }
        c ||= {
          "id" => @conversations.size + 1,
          "participants" => user_ids.map{|uid| {"id" => uid} },
          "created_at" => Time.now,
          "updated_at" => Time.now
        }.tap {|c| @conversations << c }
        c.dup
      end

      def post(id, sender_id, body, subject_type = nil, subject_id = nil)
        id = id.to_i unless id.nil?
        sender_id = sender_id.to_i unless sender_id.nil?
        subject_id = subject_id.to_i unless subject_id.nil?

        m = {
          "id" => next_message_id,
          "conversation_id" => id,
          "user_id" => sender_id,
          "body" => body,
          "subject_type" => subject_type,
          "subject_id" => subject_id,
          "created_at" => Time.now
        }
        conversation = with_id(id)
        @active_conversation[sender_id] = conversation
        conversation["updated_at"] = Time.now
        conversation["last_message"] = m
        @messages[conversation["id"]] << m
        conversation
      end

      def messages(id, user_id, before_time = nil)
        id = id.to_i unless id.nil?
        mark_read!(id, user_id) unless before_time
        sorted_messages = []
        unless @messages[id].empty?
          sorted_messages = @messages[id].sort { |x, y| y["created_at"] <=> x["created_at"] }

          if before_time
            start_idx = sorted_messages.index { |m| m["created_at"] < before_time }
          else
            start_idx = 0
          end

          sorted_messages = sorted_messages[start_idx..start_idx+PAGE_SIZE-1] if start_idx
        end
        {
          "messages" => sorted_messages,
          "earlier_message_count" => sorted_messages.empty? ? 0 : count(id, sorted_messages.last["created_at"]),
          "unread_conversation_count" => self.unread_conversation_count_for_user_id(user_id)
        }
      end

      def mark_read!(id, user_id)
        conversation = with_id(id)
        participant = conversation["participants"].find{|p| p["id"] == user_id }
        participant.merge!('last_read_at' => Time.now)
      end

      def conversation_by_id_and_user_id(id, user_id)
        @conversations.find { |c| c["id"] == id && c["participants"].map { |p| p["id"] }.include?(user_id) } || raise(QuikChat::RecordNotFound)
      end

      def unread_conversation_count_for_user_id(user_id)
        all_conversations = @conversations.select{|c| c["participants"].map{|p| p['id'] }.include?(user_id) }
        unread_conversations = all_conversations.select do |c|
          p = c['participants'].select{|p| p['id'] == user_id}.first
          p['last_read_at'] == nil || p['last_read_at'] < c['updated_at']
        end
        unread_conversations.count
      end

    protected

      def count(id, before_time=nil)
        id = id.to_i unless id.nil?
        return 0 if @messages[id].empty?
        sorted_messages = @messages[id].sort { |x, y| y["created_at"] <=> x["created_at"] }

        if before_time
          sorted_messages.select! { |m| m["created_at"] < before_time }
        end

        sorted_messages.count
      end

      def next_message_id
        ids = @messages.values.flatten.map{|m| m["id"] }
        ids.empty? ? 1 : (ids.max + 1)
      end

      def with_id(id)
        @conversations.find{|c| c["id"] == id } || raise(QuikChat::RecordNotFound)
      end

    end
  end
end
