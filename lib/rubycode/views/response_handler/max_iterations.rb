# frozen_string_literal: true

require "tty-box"

module RubyCode
  module Views
    module ResponseHandler
      # Builds max iterations warning box
      class MaxIterations
        def self.build(max_iterations:)
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
            "Reached maximum iterations (#{max_iterations})\nThe agent may be stuck in a loop."
          end
          "\n#{error_box}"
        end
      end
    end
  end
end
