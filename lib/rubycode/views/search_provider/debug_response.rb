# frozen_string_literal: true

require "pastel"

module RubyCode
  module Views
    module SearchProvider
      # Builds debug response text for search provider responses
      class DebugResponse
        def self.build(provider_name:, status_code:, body_preview:)
          pastel = Pastel.new
          content = []
          content << ""
          content << pastel.green.bold("=== DEBUG SEARCH RESPONSE ===")
          content << "#{pastel.bold("Provider:")} #{provider_name}"
          content << "#{pastel.bold("Status:")} #{status_code}"
          content << ""
          content << pastel.bold("Response Preview:")
          content << body_preview
          content << pastel.green.bold("=" * 29)
          content.join("\n")
        end
      end
    end
  end
end
