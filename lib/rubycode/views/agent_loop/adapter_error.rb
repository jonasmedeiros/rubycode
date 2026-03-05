# frozen_string_literal: true

module RubyCode
  module Views
    module AgentLoop
      # Builds adapter error message
      class AdapterError
        def self.build(message:)
          "   ✗ Adapter Error: #{message}"
        end
      end
    end
  end
end
