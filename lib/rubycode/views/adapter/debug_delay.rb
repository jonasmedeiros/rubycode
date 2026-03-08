# frozen_string_literal: true

module RubyCode
  module Views
    module Adapter
      # Displays rate limit delay debug information
      class DebugDelay
        def self.build(adapter_name:, delay:)
          pastel = Pastel.new

          [
            "",
            pastel.yellow("⏱️  Rate limit delay: #{delay}s (#{adapter_name})"),
            ""
          ].join("\n")
        end
      end
    end
  end
end
