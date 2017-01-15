require 'uri'

class QuikChat
  class Configuration
    attr_accessor :adapter, :quikchat_url

    def quikchat_uri
      raise "quikchat_url needs to be set! e.g. QuikChat.configuration.quikchat_url = 'http://example.com'" unless quikchat_url
      @quikchat_uri ||= URI.parse(quikchat_url)
    end

    def adapter
      raise "Adapter needs to be set! e.g. QuikChat.configuration.adapter = QuikChat::Adapter::[HTTP|Fake].new" unless @adapter
      @adapter
    end
  end
end
