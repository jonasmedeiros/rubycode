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

    def to_llm_format(window_size: 10, prune_tool_results: true)
      all_messages = messages
      return all_messages.map(&:to_h) if all_messages.length <= window_size

      build_windowed_format(all_messages, window_size, prune_tool_results)
    end

    def build_windowed_format(all_messages, window_size, prune_tool_results)
      first_msg, recent, middle = partition_messages(all_messages, window_size)

      return recent.map(&:to_h) if recent.include?(first_msg)

      result_messages = build_message_list(first_msg, middle, recent, prune_tool_results)
      result_messages.map(&:to_h)
    end

    def build_message_list(first_msg, middle, recent, prune_tool_results)
      return [first_msg] + recent unless should_prune_middle?(prune_tool_results, middle)

      pruned_middle = prune_tool_results_from_middle(middle)
      [first_msg] + pruned_middle + recent
    end

    def partition_messages(all_messages, window_size)
      first_msg = all_messages.first
      recent = all_messages.last(window_size)
      middle = all_messages[1..-(window_size + 1)] || []
      [first_msg, recent, middle]
    end

    def should_prune_middle?(prune_tool_results, middle)
      prune_tool_results && middle.any? { |msg| tool_result_message?(msg) }
    end

    def tool_result_message?(message)
      message.role == "user" && message.content.start_with?("Tool '")
    end

    def prune_tool_results_from_middle(middle)
      middle.map do |msg|
        if tool_result_message?(msg)
          Message.new(role: msg.role, content: "[Tool result cleared]")
        else
          msg
        end
      end
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
