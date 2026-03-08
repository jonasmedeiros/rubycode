# frozen_string_literal: true

module RubyCode
  class Client
    # Handles response scenarios (max iterations, empty tool calls, etc.)
    class ResponseHandler
      MAX_ITERATIONS = 25
      MAX_TOOL_CALLS = 50

      def initialize(memory:, config:)
        @memory = memory
        @config = config
      end

      def handle_max_iterations(_iteration)
        puts Views::ResponseHandler::MaxIterations.build(max_iterations: MAX_ITERATIONS)

        error_msg = I18n.t("rubycode.errors.max_iterations_reached")
        @memory.add_message(role: "assistant", content: error_msg)
        error_msg
      end

      def handle_empty_tool_calls(content, iteration, total_tool_calls)
        puts Views::ResponseHandler::CompleteMessage.build(iteration: iteration,
                                                           total_tool_calls: total_tool_calls)
        content
      end

      def handle_max_tool_calls(content, _total_tool_calls)
        puts Views::ResponseHandler::MaxToolCalls.build(max_tool_calls: MAX_TOOL_CALLS)

        error_msg = I18n.t("rubycode.errors.max_tool_calls_reached")
        @memory.add_message(role: "assistant", content: error_msg)
        content.empty? ? error_msg : content
      end

      def finalize_response(done_result, iteration, total_tool_calls)
        puts Views::ResponseHandler::AgentFinished.build(iteration: iteration,
                                                         total_tool_calls: total_tool_calls + 1)
        done_result
      end
    end
  end
end
