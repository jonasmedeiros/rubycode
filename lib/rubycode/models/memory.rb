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
    def add_message(message = nil, role: nil, content: nil, tool_calls: nil)
      if message.is_a?(Message)
        insert_message(message.role, message.content, message.tool_calls)
      elsif role && content
        insert_message(role, content, tool_calls)
      else
        raise ArgumentError, "Must provide either a Message object or role: and content: keyword arguments"
      end
    end

    def messages
      db[:messages].order(:id).map do |row|
        Message.new(
          role: row[:role],
          content: row[:content],
          tool_calls: deserialize_tool_calls(row[:tool_calls])
        )
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

      Message.new(
        role: row[:role],
        content: row[:content],
        tool_calls: deserialize_tool_calls(row[:tool_calls])
      )
    end

    def last_assistant_message
      row = self.class.latest.where(role: "assistant").first
      return nil unless row

      Message.new(
        role: row[:role],
        content: row[:content],
        tool_calls: deserialize_tool_calls(row[:tool_calls])
      )
    end

    private

    def insert_message(role, content, tool_calls = nil)
      db[:messages].insert(
        role: role,
        content: content,
        tool_calls: serialize_tool_calls(tool_calls)
      )
    end

    def serialize_tool_calls(tool_calls)
      return nil if tool_calls.nil? || tool_calls.empty?

      JSON.generate(tool_calls)
    end

    def deserialize_tool_calls(tool_calls_json)
      return nil if tool_calls_json.nil? || tool_calls_json.empty?

      JSON.parse(tool_calls_json)
    rescue JSON::ParserError
      nil
    end
  end
end
