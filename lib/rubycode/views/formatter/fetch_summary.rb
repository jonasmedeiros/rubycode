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
          content = result.content || ""

          lines = build_header_lines(pastel, metadata, content)
          lines.concat(build_preview_lines(pastel, content))
          lines << ""

          lines.join("\n")
        end

        def self.build_header_lines(pastel, metadata, content)
          url = metadata[:url] || "Unknown URL"
          size_kb = (content.bytesize / 1024.0).round(1)
          size_bytes = content.bytesize

          [
            "",
            "   #{pastel.cyan("📥")} Fetched from: #{pastel.bold(url)}",
            "   #{pastel.dim("Status:")} Success",
            "   #{pastel.dim("Size:")} #{size_kb} KB (#{size_bytes} bytes)"
          ]
        end

        def self.build_preview_lines(pastel, content)
          first_line = content.lines.first&.strip || ""
          return [] unless first_line.length.positive?

          [
            "",
            pastel.dim("   Preview:"),
            pastel.dim("   #{truncate(first_line, 100)}")
          ]
        end

        def self.truncate(text, max_length)
          return text if text.length <= max_length

          "#{text[0...(max_length - 3)]}..."
        end
      end
    end
  end
end
