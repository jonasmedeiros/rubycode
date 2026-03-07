# frozen_string_literal: true

require "pastel"

module RubyCode
  module Views
    module Formatter
      # Builds fetch result summary display
      class FetchSummary
        def self.build(result:)
          pastel = Pastel.new
          metadata = result.metadata || {}
          url = metadata[:url] || "Unknown URL"
          content = result.content || ""
          size_kb = (content.bytesize / 1024.0).round(1)
          size_bytes = content.bytesize

          lines = [
            "",
            "   #{pastel.cyan("📥")} Fetched from: #{pastel.bold(url)}",
            "   #{pastel.dim("Status:")} Success",
            "   #{pastel.dim("Size:")} #{size_kb} KB (#{size_bytes} bytes)"
          ]

          # Show first line preview if available
          first_line = content.lines.first&.strip || ""
          if first_line.length.positive?
            lines << ""
            lines << pastel.dim("   Preview:")
            lines << pastel.dim("   #{truncate(first_line, 100)}")
          end

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
