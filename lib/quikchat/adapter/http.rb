require 'httparty'

class QuikChat
  module Adapter
    class HTTP
      attr_accessor :error_delegate

      def conversations(user_id, page = 1)
        get_request("/users/#{user_id}/conversations/#{page}")
      end

      def active_conversation(user_id)
        get_request("/users/#{user_id}/active_conversation", wrapper: 'conversations').first
      end

      def with_user_ids(user_ids)
        post_request("/conversations", params: { user_ids: user_ids }, wrapper: 'conversations').first
      end

      def post(id, user_id, body, subject_type = nil, subject_id = nil)
        params = { user_id: user_id, body: body, subject_type: subject_type, subject_id: subject_id }
        post_request("/conversations/#{id}/messages", params: { user_id: user_id, message: params }, wrapper: 'conversations').first
      end

      def messages(id, user_id, before_time = nil)
        params = {user_id: user_id}
        params[:before_time] = before_time.iso8601(6) if before_time
        get_request("/conversations/#{id}/messages", params: params)
      end

      def mark_read!(id, user_id)
        post_request("/conversations/#{id}/mark_as_read", params: {user_id: user_id})
      end

      def conversation_by_id_and_user_id(id, user_id)
        params = {user_id: user_id}
        get_request("/conversations/#{id}", params: params, wrapper: 'conversation')
      end

      def unread_conversation_count_for_user_id(user_id)
        begin
          get_request("/users/#{user_id}/unread_conversation_count", wrapper: 'unread_count')
        rescue Exception => e
          error_delegate.notice_error(e, custom_params: {user_id: user_id}) if error_delegate && error_delegate.respond_to?(:notice_error)
          0
        end
      end

    protected

      def get_request(url, params: {}, wrapper: nil)
        response = HTTParty.get(quikchat_url(url), {query: params}.merge(default_options))
        json_response = JSON.parse(response.body)

        wrapper.nil? ? json_response : json_response[wrapper]
      end

      def post_request(url, params: {}, wrapper: nil)
        response = HTTParty.post(quikchat_url(url), {body: params.to_json}.merge(default_options(content_type_json: true, timeout: 2)))
        json_response = JSON.parse(response.body)

        wrapper.nil? ? json_response : json_response[wrapper]
      end

      def quikchat_url(path)
        (QuikChat.configuration.quikchat_uri + path).to_s
      end

      def default_options(content_type_json: false, timeout: 1)
        headers = {headers: {'Accept' => 'application/json'}}
        headers[:headers].merge!({'Content-Type' => 'application/json'}) if content_type_json
        {timeout: timeout}.merge(headers)
      end

    end
  end
end
