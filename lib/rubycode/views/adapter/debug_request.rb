# frozen_string_literal: true

require "pastel"
require "json"

module RubyCode
  module Views
    module Adapter
      # Builds debug request text for adapter API calls
      class DebugRequest
        def self.build(adapter_name:, url:, model:, payload:)
          pastel = Pastel.new
          content = build_content_lines(pastel, adapter_name, url, model, payload)
          content.join("\n")
        end

        def self.build_content_lines(pastel, adapter_name, url, model, payload)
          [
            "",
            pastel.yellow.bold("=== DEBUG REQUEST ==="),
            "#{pastel.bold("Adapter:")} #{adapter_name}",
            "#{pastel.bold("URL:")} #{url}",
            "#{pastel.bold("Model:")} #{model}",
            "",
            pastel.bold("Payload:"),
            JSON.pretty_generate(payload),
            pastel.yellow.bold("=" * 21)
          ]
        end
      end
    end
  end
end
