# frozen_string_literal: true

require "json"
require "pastel"

module RubyCode
  class Client
    # Handles formatting and display of tool information and results
    class DisplayFormatter
      TOOL_LABELS = {
        "bash" => ["[BASH]", "command"],
        "read" => ["[READ]", "file_path"],
        "search" => ["[SEARCH]", "pattern"],
        "write" => ["[WRITE]", "file_path"],
        "update" => ["[UPDATE]", "file_path"]
      }.freeze

      def initialize(config:)
        @config = config
        @pastel = Pastel.new
      end

      def display_tool_info(tool_name, arguments)
        if @config.debug
          puts Views::Formatter::DebugToolInfo.build(tool_name: tool_name, arguments: arguments)
        else
          display_minimal_tool_info(tool_name, arguments)
        end
      end

      def display_result(result)
        return unless @config.debug

        puts Views::Formatter::ToolResult.build(result: result)
      end

      def display_info(message)
        puts Views::Formatter::InfoMessage.build(message: message)
      end

      def display_skip_notification(_tool_name, detail)
        puts @pastel.yellow("   ⓘ Skipped: #{detail}")
      end

      private

      def display_minimal_tool_info(tool_name, arguments)
        return unless TOOL_LABELS.key?(tool_name)

        label, key = TOOL_LABELS[tool_name]
        value = extract_argument_value(arguments, key)
        return unless value

        puts Views::Formatter::MinimalToolInfo.build(
          label: label,
          value: truncate_value(value, 60)
        )
      end

      def truncate_value(value, max_length)
        return value if value.length <= max_length

        "#{value[0...(max_length - 3)]}..."
      end

      def extract_argument_value(arguments, key)
        arguments.is_a?(Hash) ? arguments[key] : JSON.parse(arguments)[key]
      rescue JSON::ParserError
        nil
      end
    end
  end
end
