# frozen_string_literal: true

require "tty-box"

module RubyCode
  module Views
    module ResponseHandler
      # Builds agent finished success box
      class AgentFinished
        def self.build(iteration:, total_tool_calls:)
          success_box = TTY::Box.frame(
            title: { top_left: " #{I18n.t("rubycode.response_handler.agent_finished.title")} " },
            border: :light,
            padding: 1,
            style: {
              fg: :green,
              border: {
                fg: :green
              }
            }
          ) do
            I18n.t("rubycode.response_handler.agent_finished.message",
                   iterations: iteration,
                   tool_calls: total_tool_calls)
          end
          "\n#{success_box}"
        end
      end
    end
  end
end
