# frozen_string_literal: true

require "tty-box"

module RubyCode
  module Views
    module ResponseHandler
      # Builds max tool calls warning box
      class MaxToolCalls
        def self.build(max_tool_calls:)
          error_box = TTY::Box.frame(
            title: { top_left: " ⚠ WARNING " },
            border: :thick,
            padding: 1,
            style: {
              fg: :yellow,
              border: {
                fg: :yellow
              }
            }
          ) do
            "Reached maximum tool calls (#{max_tool_calls})\nStopping to prevent excessive operations."
          end
          "\n#{error_box}"
        end
      end
    end
  end
end
