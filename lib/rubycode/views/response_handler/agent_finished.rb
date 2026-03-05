# frozen_string_literal: true

require "tty-box"

module RubyCode
  module Views
    module ResponseHandler
      # Builds agent finished success box
      class AgentFinished
        def self.build(iteration:, total_tool_calls:)
          success_box = TTY::Box.frame(
            title: { top_left: " ✓ SUCCESS " },
            border: :light,
            padding: 1,
            style: {
              fg: :green,
              border: {
                fg: :green
              }
            }
          ) do
            "Agent finished\n#{iteration} iterations, #{total_tool_calls} tool calls"
          end
          "\n#{success_box}"
        end
      end
    end
  end
end
