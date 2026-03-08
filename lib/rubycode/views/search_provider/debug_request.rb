# frozen_string_literal: true

require "pastel"

module RubyCode
  module Views
    module SearchProvider
      # Builds debug request text for search provider requests
      class DebugRequest
        def self.build(provider_name:, query:, max_results:, url:)
          pastel = Pastel.new
          content = build_content_lines(pastel, provider_name, query, max_results, url)
          content.join("\n")
        end

        def self.build_content_lines(pastel, provider_name, query, max_results, url)
          [
            "",
            pastel.yellow.bold("=== DEBUG SEARCH REQUEST ==="),
            "#{pastel.bold("Provider:")} #{provider_name}",
            "#{pastel.bold("Query:")} #{query}",
            "#{pastel.bold("Max Results:")} #{max_results}",
            "#{pastel.bold("URL:")} #{url}",
            pastel.yellow.bold("=" * 28)
          ]
        end
      end
    end
  end
end
