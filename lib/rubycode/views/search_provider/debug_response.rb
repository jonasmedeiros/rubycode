# frozen_string_literal: true

require "pastel"

module RubyCode
  module Views
    module SearchProvider
      # Builds debug response text for search provider responses
      class DebugResponse
        def self.build(provider_name:, status_code:, body_preview:)
          pastel = Pastel.new
          content = build_content_lines(pastel, provider_name, status_code, body_preview)
          content.join("\n")
        end

        def self.build_content_lines(pastel, provider_name, status_code, body_preview)
          [
            "",
            pastel.green.bold("=== DEBUG SEARCH RESPONSE ==="),
            "#{pastel.bold("Provider:")} #{provider_name}",
            "#{pastel.bold("Status:")} #{status_code}",
            "",
            pastel.bold("Response Preview:"),
            body_preview,
            pastel.green.bold("=" * 29)
          ]
        end
      end
    end
  end
end
