# frozen_string_literal: true

module Rubycode
  class History
    def initialize
      @messages = []
    end

    def add_message(role:, content:)
      @messages << {
        role: role,
        content: content,
        timestamp: Time.now
      }
    end

    def to_llm_format
      @messages.map { |msg| { role: msg[:role], content: msg[:content] } }
    end

    def clear
      @messages = []
    end

    def messages
      @messages
    end

    def last_user_message
      @messages.reverse.find { |msg| msg[:role] == "user" }
    end

    def last_assistant_message
      @messages.reverse.find { |msg| msg[:role] == "assistant" }
    end
  end
end
