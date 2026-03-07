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
          content = []
          content << ""
          content << pastel.yellow.bold("=== DEBUG REQUEST ===")
          content << "#{pastel.bold("Adapter:")} #{adapter_name}"
          content << "#{pastel.bold("URL:")} #{url}"
          content << "#{pastel.bold("Model:")} #{model}"
          content << ""
          content << pastel.bold("Payload:")
          content << JSON.pretty_generate(payload)
          content << pastel.yellow.bold("=" * 21)
          content.join("\n")
        end
      end
    end
  end
end
