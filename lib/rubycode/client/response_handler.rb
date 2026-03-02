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
        error_msg = "⚠️  Reached maximum iterations (#{MAX_ITERATIONS}). The agent may be stuck in a loop."
        puts "\n#{error_msg}\n"
        @history.add_message(role: "assistant", content: error_msg)
        error_msg
      end

      def handle_empty_tool_calls(content, iteration, total_tool_calls)
        if @config.enable_tool_injection_workaround && iteration < 10
          inject_tool_reminder(iteration)
          return nil
        end

        puts "\n✅ Agent finished (#{iteration} iterations, #{total_tool_calls} tool calls)\n" unless @config.debug
        content
      end

      def handle_max_tool_calls(content, _total_tool_calls)
        error_msg = "⚠️  Reached maximum tool calls (#{MAX_TOOL_CALLS}). Stopping to prevent excessive operations."
        puts "\n#{error_msg}\n"
        @history.add_message(role: "assistant", content: error_msg)
        content.empty? ? error_msg : content
      end

      def finalize_response(done_result, iteration, total_tool_calls)
        puts "\n✅ Agent finished (#{iteration} iterations, #{total_tool_calls + 1} tool calls)\n" unless @config.debug
        done_result
      end

      private

      def inject_tool_reminder(iteration)
        puts "   ⚠️  No tool calls - injecting reminder (iteration #{iteration})" unless @config.debug
        @history.add_message(
          role: "user",
          content: "You MUST call a tool. Do not respond with text. Call search, read, bash, or done tool now."
        )
      end
    end
  end
end
