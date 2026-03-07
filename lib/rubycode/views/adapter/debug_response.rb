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

          content = []
          content << ""
          content << pastel.green.bold("=== DEBUG RESPONSE ===")
          content << "#{pastel.bold("Adapter:")} #{adapter_name}"
          content << ""
          content << pastel.bold("Response:")
          content << JSON.pretty_generate(body)
          content << pastel.green.bold("=" * 22)
          content.join("\n")
        end
      end
    end
  end
end
