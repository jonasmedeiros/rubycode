# frozen_string_literal: true

require "pastel"

module RubyCode
  module Views
    module Formatter
      # Builds web search result summary display
      class WebSearchSummary
        def self.build(result:)
          pastel = Pastel.new
          metadata = result.metadata || {}
          count = metadata[:result_count] || 0
          results = metadata[:results] || []

          lines = [
            "",
            "   #{pastel.cyan("✓")} Found #{count} result(s):"
          ]

          # Show first 3 results
          results.first(3).each_with_index do |item, idx|
            lines << pastel.dim("     #{idx + 1}. #{item[:title]}")
            lines << pastel.dim("        #{truncate(item[:url], 70)}")
          end

          lines << pastel.dim("     ...") if results.length > 3
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
