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

          lines = build_header_lines(pastel, metadata)
          lines.concat(build_result_lines(pastel, metadata[:results] || []))

          lines.join("\n")
        end

        def self.build_header_lines(pastel, metadata)
          count = metadata[:result_count] || 0
          provider = metadata[:provider] || "Search"

          [
            "",
            "   #{pastel.cyan("✓")} Found #{count} result(s) from #{provider}:",
            ""
          ]
        end

        def self.build_result_lines(pastel, results)
          results.flat_map.with_index do |item, idx|
            build_single_result(pastel, item, idx)
          end
        end

        def self.build_single_result(pastel, item, idx)
          lines = [
            "   #{pastel.bold("#{idx + 1}. #{item[:title]}")}",
            pastel.cyan("      #{item[:url]}")
          ]
          lines << pastel.dim("      #{item[:snippet]}") if snippet?(item)
          lines << ""
          lines
        end

        def self.snippet?(item)
          item[:snippet] && !item[:snippet].empty?
        end
      end
    end
  end
end
