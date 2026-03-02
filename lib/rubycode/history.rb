# frozen_string_literal: true

module RubyCode
  # Manages conversation history between user and assistant
  class History
    attr_reader :messages

    def initialize
      @messages = []
    end

    # Accept either Message objects or keyword arguments for backwards compatibility
    def add_message(message = nil, role: nil, content: nil)
      if message.is_a?(Message)
        @messages << message
      elsif role && content
        @messages << Message.new(role: role, content: content)
      else
        raise ArgumentError, "Must provide either a Message object or role: and content: keyword arguments"
      end
    end

    def to_llm_format
      @messages.map(&:to_h)
    end

    def clear
      @messages = []
    end

    def last_user_message
      @messages.reverse.find { |msg| msg.role == "user" }
    end

    def last_assistant_message
      @messages.reverse.find { |msg| msg.role == "assistant" }
    end
  end
end
