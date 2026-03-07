# frozen_string_literal: true

require "pastel"

module RubyCode
  module Views
    module SearchProvider
      # Builds debug request text for search provider requests
      class DebugRequest
        def self.build(provider_name:, query:, max_results:, url:)
          pastel = Pastel.new
          content = []
          content << ""
          content << pastel.yellow.bold("=== DEBUG SEARCH REQUEST ===")
          content << "#{pastel.bold("Provider:")} #{provider_name}"
          content << "#{pastel.bold("Query:")} #{query}"
          content << "#{pastel.bold("Max Results:")} #{max_results}"
          content << "#{pastel.bold("URL:")} #{url}"
          content << pastel.yellow.bold("=" * 28)
          content.join("\n")
        end
      end
    end
  end
end
