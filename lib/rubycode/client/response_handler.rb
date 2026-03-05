# frozen_string_literal: true

require "tty-box"
require "pastel"

module RubyCode
  class Client
    # Handles response scenarios (max iterations, empty tool calls, etc.)
    class ResponseHandler
      MAX_ITERATIONS = 25
      MAX_TOOL_CALLS = 50

      def initialize(history:, config:)
        @history = history
        @config = config
        @pastel = Pastel.new
      end

      def handle_max_iterations(_iteration)
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
          "Reached maximum iterations (#{MAX_ITERATIONS})\nThe agent may be stuck in a loop."
        end
        puts "\n#{error_box}"

        error_msg = "Reached maximum iterations"
        @history.add_message(role: "assistant", content: error_msg)
        error_msg
      end

      def handle_empty_tool_calls(content, iteration, total_tool_calls)
        if @config.enable_tool_injection_workaround && iteration < 10
          inject_tool_reminder(iteration)
          return nil
        end

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
          "Task completed\n#{iteration} iterations, #{total_tool_calls} tool calls"
        end
        puts "\n#{success_box}" unless @config.debug
        content
      end

      def handle_max_tool_calls(content, _total_tool_calls)
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
          "Reached maximum tool calls (#{MAX_TOOL_CALLS})\nStopping to prevent excessive operations."
        end
        puts "\n#{error_box}"

        error_msg = "Reached maximum tool calls"
        @history.add_message(role: "assistant", content: error_msg)
        content.empty? ? error_msg : content
      end

      def finalize_response(done_result, iteration, total_tool_calls)
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
          "Agent finished\n#{iteration} iterations, #{total_tool_calls + 1} tool calls"
        end
        puts "\n#{success_box}" unless @config.debug
        done_result
      end

      private

      def inject_tool_reminder(iteration)
        puts "   #{@pastel.yellow("[WARNING]")} No tool calls - injecting reminder (iteration #{iteration})" unless @config.debug
        @history.add_message(
          role: "user",
          content: "You MUST call a tool. Do not respond with text. Call search, read, bash, or done tool now."
        )
      end
    end
  end
end
