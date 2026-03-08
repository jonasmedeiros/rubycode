# frozen_string_literal: true

require_relative "client/response_handler"
require_relative "client/display_formatter"
require_relative "client/approval_handler"

module RubyCode
  # Manages the agent loop - iterates until task completion or limits reached
  class AgentLoop
    MAX_ITERATIONS = 25
    MAX_TOOL_CALLS = 50
    MAX_CONSECUTIVE_RATE_LIMIT_ERRORS = 3

    attr_reader :approval_handler

    def initialize(adapter:, memory:, config:, system_prompt:, options: {})
      @adapter = adapter
      @memory = memory
      @config = config
      @system_prompt = system_prompt
      @read_files = options[:read_files]
      @tty_prompt = options[:tty_prompt]
      @options = options
      @response_handler = Client::ResponseHandler.new(memory: @memory, config: @config)
      @display_formatter = Client::DisplayFormatter.new(config: @config)
      @approval_handler = options[:approval_handler] ||
                          Client::ApprovalHandler.new(tty_prompt: @tty_prompt, config: @config)
      @consecutive_rate_limit_errors = 0
    end

    def run
      iteration = 0
      total_tool_calls = 0
      @last_response_was_error = false

      loop do
        iteration += 1

        return @response_handler.handle_max_iterations(iteration) if iteration > MAX_ITERATIONS

        content, tool_calls = llm_response

        next if handle_empty_tool_calls_case(content, tool_calls, iteration, total_tool_calls)

        total_tool_calls += tool_calls.length
        return @response_handler.handle_max_tool_calls(content, total_tool_calls) if total_tool_calls > MAX_TOOL_CALLS

        done_result = execute_tool_calls(tool_calls, iteration)
        return @response_handler.finalize_response(done_result, iteration, total_tool_calls) if done_result
      end
    rescue RubyCode::AdapterRetryExhaustedError => e
      build_retry_exhausted_message(e)
    end

    def handle_empty_tool_calls_case(content, tool_calls, iteration, total_tool_calls)
      return false unless tool_calls.empty?

      # Skip empty tool call handling if last response was an adapter error
      if @last_response_was_error
        @last_response_was_error = false # Reset flag
        return true # Continue loop
      end

      result = @response_handler.handle_empty_tool_calls(content, iteration, total_tool_calls)
      return result if result

      false
    end

    def build_retry_exhausted_message(error)
      "\n❌ Unable to reach LLM server after multiple retries.\n\n" \
        "Error: #{error.message}\n\n" \
        "Please check:\n  " \
        "• Is your LLM server running?\n  " \
        "• Are you being rate limited? (wait a few minutes)\n  " \
        "• Is the server URL correct in your config?\n"
    end

    private

    def llm_response
      puts Views::AgentLoop::ThinkingStatus.build

      response_body = fetch_llm_response
      display_response_info(response_body)

      content, tool_calls = extract_message_parts(response_body)

      reset_error_tracking
      @memory.add_message(role: "assistant", content: content, tool_calls: tool_calls)

      [content, tool_calls]
    rescue RubyCode::AdapterRetryExhaustedError => e
      # Stop the agent loop when retries are exhausted
      handle_retry_exhausted(e)
      raise e # Re-raise to stop the loop
    rescue RubyCode::AdapterError => e
      handle_adapter_error_with_rate_limiting(e)
      @last_response_was_error = true # Mark as error to skip injection reminder
      [nil, []] # Return empty to continue loop
    end

    def fetch_llm_response
      messages = @memory.to_llm_format(
        window_size: @config.memory_window,
        prune_tool_results: @config.prune_tool_results
      )

      # Filter tools if allowed_tools is specified
      tools_to_send = if @options[:allowed_tools]
                        Tools.definitions.select do |t|
                          @options[:allowed_tools].include?(t[:function][:name])
                        end
                      else
                        Tools.definitions
                      end

      @adapter.generate(
        messages: messages,
        system: @system_prompt,
        tools: tools_to_send
      )
    end

    def display_response_info(_response_body)
      puts Views::AgentLoop::ResponseReceived.build

      tokens = @adapter.current_request_tokens
      cumulative = @adapter.total_tokens_counter
      puts Views::AgentLoop::TokenSummary.build(
        tokens: tokens,
        adapter: @config.adapter,
        model: @config.model,
        cumulative: cumulative
      )
    end

    def extract_message_parts(response_body)
      assistant_message = response_body["message"]
      content = assistant_message["content"] || ""
      tool_calls = assistant_message["tool_calls"] || []
      [content, tool_calls]
    end

    def reset_error_tracking
      @consecutive_rate_limit_errors = 0
      @last_response_was_error = false
    end

    def handle_adapter_error_with_rate_limiting(error)
      if rate_limit_error?(error)
        @consecutive_rate_limit_errors += 1
        if @consecutive_rate_limit_errors >= MAX_CONSECUTIVE_RATE_LIMIT_ERRORS
          handle_rate_limit_exhausted(error)
          raise AdapterRetryExhaustedError,
                "Rate limit exceeded after #{MAX_CONSECUTIVE_RATE_LIMIT_ERRORS} consecutive attempts"
        end
      else
        # Reset counter for non-rate-limit errors
        @consecutive_rate_limit_errors = 0
      end

      handle_adapter_error(error)
    end

    def handle_retry_exhausted(error)
      error_msg = I18n.t("rubycode.errors.adapter_retry_exhausted", error: error.message)
      puts Views::AgentLoop::AdapterError.build(message: error_msg)
      @memory.add_message(role: "user", content: error_msg)
    end

    def handle_adapter_error(error)
      error_msg = I18n.t("rubycode.errors.adapter_failed", error: error.message)
      puts Views::AgentLoop::AdapterError.build(message: error_msg)
      @memory.add_message(role: "user", content: error_msg)
    end

    def rate_limit_error?(error)
      error.message.include?("Rate limited") || error.message.include?("429")
    end

    def handle_rate_limit_exhausted(_error)
      error_msg = I18n.t("rubycode.errors.rate_limit_exhausted", max_attempts: MAX_CONSECUTIVE_RATE_LIMIT_ERRORS)
      puts Views::AgentLoop::AdapterError.build(message: error_msg)
      @memory.add_message(role: "user", content: error_msg)
    end

    def execute_tool_calls(tool_calls, iteration)
      puts Views::AgentLoop::IterationHeader.build(iteration: iteration, tool_calls: tool_calls)

      done_result = nil
      tool_calls.each do |tool_call|
        result = execute_tool(tool_call)

        if tool_call.dig("function", "name") == "done"
          done_result = result
          break
        end
      end

      puts Views::AgentLoop::IterationFooter.build
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

      @display_formatter.display_result(result, tool_name: tool_name)
      add_tool_result_to_memory(tool_name, result)
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
      @memory.add_message(role: "user", content: error_msg)
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
      @memory.add_message(role: "user", content: error_msg)
      nil
    end

    def add_tool_result_to_memory(tool_name, result)
      @memory.add_message(role: "user", content: "Tool '#{tool_name}' result:\n#{result}")
    end

    def handle_tool_error(error)
      error_msg = "Error: #{error.message}"
      puts Views::AgentLoop::ToolError.build(message: error_msg)
      @memory.add_message(role: "user", content: error_msg)
      nil
    end
  end
end
