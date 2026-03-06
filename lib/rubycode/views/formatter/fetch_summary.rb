# frozen_string_literal: true

require "pastel"

module RubyCode
  module Views
    module Formatter
      # Builds fetch result summary display
      class FetchSummary
        def self.build(result:)
          pastel = Pastel.new
          content = result.content || ""
          size_kb = (content.bytesize / 1024.0).round(1)

          lines = [
            "",
            "   #{pastel.cyan("✓")} Fetched content: #{size_kb} KB"
          ]

          # Show first line preview if available
          first_line = content.lines.first&.strip || ""
          lines << pastel.dim("     Preview: #{truncate(first_line, 80)}") if first_line.length.positive?

          lines << ""

          lines.join("\n")
        end

        def self.truncate(text, max_length)
          return text if text.length <= max_length

          "#{text[0...(max_length - 3)]}..."
        end
      end
    end
  end
end
