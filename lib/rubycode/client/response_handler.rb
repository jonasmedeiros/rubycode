# frozen_string_literal: true

module RubyCode
  class Client
    # Handles response scenarios (max iterations, empty tool calls, etc.)
    class ResponseHandler
      MAX_ITERATIONS = 25
      MAX_TOOL_CALLS = 50

      def initialize(history:, config:)
        @history = history
        @config = config
      end

      def handle_max_iterations(_iteration)
        puts Views::ResponseHandler::MaxIterations.build(max_iterations: MAX_ITERATIONS)

        error_msg = "Reached maximum iterations"
        @history.add_message(role: "assistant", content: error_msg)
        error_msg
      end

      def handle_empty_tool_calls(content, iteration, total_tool_calls)
        if @config.enable_tool_injection_workaround && iteration < 10
          inject_tool_reminder(iteration)
          return nil
        end

        unless @config.debug
          puts Views::ResponseHandler::CompleteMessage.build(iteration: iteration,
                                                             total_tool_calls: total_tool_calls)
        end
        content
      end

      def handle_max_tool_calls(content, _total_tool_calls)
        puts Views::ResponseHandler::MaxToolCalls.build(max_tool_calls: MAX_TOOL_CALLS)

        error_msg = "Reached maximum tool calls"
        @history.add_message(role: "assistant", content: error_msg)
        content.empty? ? error_msg : content
      end

      def finalize_response(done_result, iteration, total_tool_calls)
        unless @config.debug
          puts Views::ResponseHandler::AgentFinished.build(iteration: iteration,
                                                           total_tool_calls: total_tool_calls + 1)
        end
        done_result
      end

      private

      def inject_tool_reminder(iteration)
        puts Views::ResponseHandler::ToolInjectionWarning.build(iteration: iteration) unless @config.debug
        @history.add_message(
          role: "user",
          content: "You MUST call a tool. Do not respond with text. Call search, read, bash, or done tool now."
        )
      end
    end
  end
end
