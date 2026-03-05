# frozen_string_literal: true

module RubyCode
  # Manages conversation memory using shared database connection
  class Memory < Models::Base
    class << self
      def table_name
        :messages
      end
    end

    # Accept either Message objects or keyword arguments for backwards compatibility
    def add_message(message = nil, role: nil, content: nil)
      if message.is_a?(Message)
        insert_message(message.role, message.content)
      elsif role && content
        insert_message(role, content)
      else
        raise ArgumentError, "Must provide either a Message object or role: and content: keyword arguments"
      end
    end

    def messages
      db[:messages].order(:id).map do |row|
        Message.new(role: row[:role], content: row[:content])
      end
    end

    def to_llm_format
      messages.map(&:to_h)
    end

    def clear
      db[:messages].delete
    end

    def last_user_message
      row = self.class.latest.where(role: "user").first
      return nil unless row

      Message.new(role: row[:role], content: row[:content])
    end

    def last_assistant_message
      row = self.class.latest.where(role: "assistant").first
      return nil unless row

      Message.new(role: row[:role], content: row[:content])
    end

    private

    def insert_message(role, content)
      db[:messages].insert(role: role, content: content)
    end
  end
end
