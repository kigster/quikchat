class QuikChat
  class Message
    ATTRS = [:id, :conversation_id, :user_id, :body, :subject_type, :subject_id, :created_at]
    attr_reader(*ATTRS)

    def initialize(attrs)
      raise ArgumentError, "initialize with a hash, not #{attrs.inspect}" unless attrs.is_a?(Hash)
      ATTRS.each { |name| instance_variable_set "@#{name}", attrs[name.to_s] || attrs[name] }
    end

    def ==(other)
      self.id == other.id
    end

  end
end
