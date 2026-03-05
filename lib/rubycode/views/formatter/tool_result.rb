# frozen_string_literal: true

require "pastel"

module RubyCode
  module Views
    module Formatter
      # Builds tool result summary display
      class ToolResult
        def self.build(result:)
          pastel = Pastel.new
          first_line = result.lines.first&.strip || "(empty)"
          suffix = result.lines.count > 1 ? "... (#{result.lines.count} lines)" : ""

          "   #{pastel.green("✓")} #{pastel.dim("Result:")} #{first_line}#{suffix}"
        end
      end
    end
  end
end
