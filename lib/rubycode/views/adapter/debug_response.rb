# frozen_string_literal: true

require "pastel"
require "json"

module RubyCode
  module Views
    module Adapter
      # Builds debug response text for adapter API responses
      class DebugResponse
        def self.build(adapter_name:, body:)
          pastel = Pastel.new
          content = build_content_lines(pastel, adapter_name, body)
          content.join("\n")
        end

        def self.build_content_lines(pastel, adapter_name, body)
          [
            "",
            pastel.green.bold("=== DEBUG RESPONSE ==="),
            "#{pastel.bold("Adapter:")} #{adapter_name}",
            "",
            pastel.bold("Response:"),
            JSON.pretty_generate(body),
            pastel.green.bold("=" * 22)
          ]
        end
      end
    end
  end
end
