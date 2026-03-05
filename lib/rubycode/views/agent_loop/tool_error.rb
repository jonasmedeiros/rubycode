# frozen_string_literal: true

module RubyCode
  module Views
    module AgentLoop
      # Builds tool error message
      class ToolError
        def self.build(message:)
          "   ✗ #{message}"
        end
      end
    end
  end
end
