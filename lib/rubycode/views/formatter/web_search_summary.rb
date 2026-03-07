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
          provider = metadata[:provider] || "Search"

          lines = [
            "",
            "   #{pastel.cyan("✓")} Found #{count} result(s) from #{provider}:",
            ""
          ]

          # Show ALL results with full URLs
          results.each_with_index do |item, idx|
            lines << "   #{pastel.bold("#{idx + 1}. #{item[:title]}")}"
            lines << pastel.cyan("      #{item[:url]}")
            lines << pastel.dim("      #{item[:snippet]}") if item[:snippet] && !item[:snippet].empty?
            lines << ""
          end

          lines.join("\n")
        end
      end
    end
  end
end
