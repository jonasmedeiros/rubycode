# frozen_string_literal: true

require "json"

module RubyCode
  class Client
    # Handles formatting and display of tool information and results
    class DisplayFormatter
      TOOL_ICONS = {
        "bash" => ["💻", "command"],
        "read" => ["📖", "file_path"],
        "search" => ["🔍", "pattern"]
      }.freeze

      def initialize(config:)
        @config = config
      end

      def display_tool_info(tool_name, arguments)
        if @config.debug
          puts "\n🔧 Tool: #{tool_name}"
          puts "   Args: #{arguments.inspect}"
        else
          display_minimal_tool_info(tool_name, arguments)
        end
      end

      def display_result(result)
        return unless @config.debug

        first_line = result.lines.first&.strip || "(empty)"
        suffix = result.lines.count > 1 ? "... (#{result.lines.count} lines)" : ""
        puts "   ✓ Result: #{first_line}#{suffix}"
      end

      private

      def display_minimal_tool_info(tool_name, arguments)
        return unless TOOL_ICONS.key?(tool_name)

        icon, key = TOOL_ICONS[tool_name]
        value = extract_argument_value(arguments, key)
        puts "   #{icon} #{value}" if value
      end

      def extract_argument_value(arguments, key)
        arguments.is_a?(Hash) ? arguments[key] : JSON.parse(arguments)[key]
      rescue JSON::ParserError
        nil
      end
    end
  end
end
