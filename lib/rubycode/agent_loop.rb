# frozen_string_literal: true

require_relative "client/response_handler"
require_relative "client/display_formatter"
require_relative "client/approval_handler"

module RubyCode
  # Manages the agent loop - iterates until task completion or limits reached
  class AgentLoop
    MAX_ITERATIONS = 25
    MAX_TOOL_CALLS = 50

    def initialize(adapter:, history:, config:, system_prompt:, read_files:, tty_prompt: nil)
      @adapter = adapter
      @history = history
      @config = config
      @system_prompt = system_prompt
      @read_files = read_files
      @tty_prompt = tty_prompt
      @response_handler = Client::ResponseHandler.new(history: @history, config: @config)
      @display_formatter = Client::DisplayFormatter.new(config: @config)
      @approval_handler = Client::ApprovalHandler.new(tty_prompt: @tty_prompt, config: @config)
    end

    def run
      iteration = 0
      total_tool_calls = 0

      loop do
        iteration += 1

        return @response_handler.handle_max_iterations(iteration) if iteration > MAX_ITERATIONS

        content, tool_calls = llm_response

        if tool_calls.empty?
          result = @response_handler.handle_empty_tool_calls(content, iteration, total_tool_calls)
          return result if result

          next # Continue loop for workaround case
        end

        total_tool_calls += tool_calls.length
        return @response_handler.handle_max_tool_calls(content, total_tool_calls) if total_tool_calls > MAX_TOOL_CALLS

        done_result = execute_tool_calls(tool_calls, iteration)
        return @response_handler.finalize_response(done_result, iteration, total_tool_calls) if done_result
      end
    end

    private

    def llm_response
      puts Views::AgentLoop::ThinkingStatus.build unless @config.debug

      messages = @history.to_llm_format
      response_body = @adapter.generate(
        messages: messages,
        system: @system_prompt,
        tools: Tools.definitions
      )

      puts Views::AgentLoop::ResponseReceived.build unless @config.debug

      assistant_message = response_body["message"]
      content = assistant_message["content"] || ""
      tool_calls = assistant_message["tool_calls"] || []

      @history.add_message(role: "assistant", content: content)
      [content, tool_calls]
    end

    def execute_tool_calls(tool_calls, iteration)
      unless @config.debug
        puts Views::AgentLoop::IterationHeader.build(iteration: iteration, tool_calls: tool_calls)
      end

      done_result = nil
      tool_calls.each do |tool_call|
        result = execute_tool(tool_call)

        if tool_call.dig("function", "name") == "done"
          done_result = result
          break
        end
      end

      puts Views::AgentLoop::IterationFooter.build unless @config.debug
      done_result
    end

    def execute_tool(tool_call)
      tool_name = tool_call.dig("function", "name")
      arguments = tool_call.dig("function", "arguments")

      @display_formatter.display_tool_info(tool_name, arguments)

      params = parse_arguments(arguments)
      return nil unless params

      result = run_tool(tool_name, params)
      return nil unless result

      @display_formatter.display_result(result)
      add_tool_result_to_history(tool_name, result)
      result
    rescue ToolError, StandardError => e
      # Handle all errors - add to history and continue
      handle_tool_error(e)
    end

    def parse_arguments(arguments)
      arguments.is_a?(Hash) ? arguments : JSON.parse(arguments)
    rescue JSON::ParserError => e
      error_msg = "Error parsing tool arguments: #{e.message}"
      puts Views::AgentLoop::ToolError.build(message: error_msg)
      @history.add_message(role: "user", content: error_msg)
      nil
    end

    def run_tool(tool_name, params)
      context = {
        root_path: @config.root_path,
        read_files: @read_files,
        tty_prompt: @tty_prompt,
        approval_handler: @approval_handler,
        display_formatter: @display_formatter
      }
      Tools.execute(tool_name: tool_name, params: params, context: context)
    rescue ToolError => e
      # Re-raise tool errors to be caught by execute_tool
      raise e
    rescue StandardError => e
      # Wrap unexpected errors
      error_msg = "Error executing tool: #{e.message}"
      puts Views::AgentLoop::ToolError.build(message: error_msg)
      @history.add_message(role: "user", content: error_msg)
      nil
    end

    def add_tool_result_to_history(tool_name, result)
      @history.add_message(role: "user", content: "Tool '#{tool_name}' result:\n#{result}")
    end

    def handle_tool_error(error)
      error_msg = "Error: #{error.message}"
      puts Views::AgentLoop::ToolError.build(message: error_msg)
      @history.add_message(role: "user", content: error_msg)
      nil
    end
  end
end
