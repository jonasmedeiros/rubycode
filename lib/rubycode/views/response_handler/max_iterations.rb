# frozen_string_literal: true

require "tty-box"

module RubyCode
  module Views
    module ResponseHandler
      # Builds max iterations warning box
      class MaxIterations
        def self.build(max_iterations:)
          error_box = TTY::Box.frame(
            title: { top_left: " #{I18n.t("rubycode.response_handler.max_iterations.title")} " },
            border: :thick,
            padding: 1,
            style: {
              fg: :yellow,
              border: {
                fg: :yellow
              }
            }
          ) do
            I18n.t("rubycode.response_handler.max_iterations.message", max: max_iterations)
          end
          "\n#{error_box}"
        end
      end
    end
  end
end
