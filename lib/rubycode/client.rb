# frozen_string_literal: true

module Rubycode
  class Client
    attr_reader :history

    def initialize
      @config = Rubycode.config
      @adapter = build_adapter
      @history = History.new
    end

    MAX_ITERATIONS = 25  # Maximum number of LLM calls per request
    MAX_TOOL_CALLS = 50  # Maximum total tool calls

    def ask(prompt:)
      @history.add_message(role: "user", content: prompt)
      system_prompt = build_system_prompt
      iteration = 0
      total_tool_calls = 0

      loop do
        iteration += 1

        return handle_max_iterations(iteration) if iteration > MAX_ITERATIONS

        content, tool_calls = get_llm_response(system_prompt)

        if tool_calls.empty?
          result = handle_empty_tool_calls(content, iteration, total_tool_calls)
          return result if result

          next # Continue loop for workaround case
        end

        total_tool_calls += tool_calls.length
        return handle_max_tool_calls(content, total_tool_calls) if total_tool_calls > MAX_TOOL_CALLS

        done_result = execute_tool_calls(tool_calls, iteration)
        return finalize_response(done_result, iteration, total_tool_calls) if done_result
      end
    end

    private

    def handle_max_iterations(iteration)
      error_msg = "⚠️  Reached maximum iterations (#{MAX_ITERATIONS}). The agent may be stuck in a loop."
      puts "\n#{error_msg}\n"
      @history.add_message(role: "assistant", content: error_msg)
      error_msg
    end

    def get_llm_response(system_prompt)
      messages = @history.to_llm_format
      response_body = @adapter.generate(
        messages: messages,
        system: system_prompt,
        tools: Tools.definitions
      )

      assistant_message = response_body["message"]
      content = assistant_message["content"] || ""
      tool_calls = assistant_message["tool_calls"] || []

      @history.add_message(role: "assistant", content: content)
      [content, tool_calls]
    end

    def handle_empty_tool_calls(content, iteration, total_tool_calls)
      if @config.enable_tool_injection_workaround && iteration < 10
        inject_tool_reminder(iteration)
        return nil
      end

      puts "\n✅ Agent finished (#{iteration} iterations, #{total_tool_calls} tool calls)\n" unless @config.debug
      content
    end

    def inject_tool_reminder(iteration)
      puts "   ⚠️  No tool calls - injecting reminder (iteration #{iteration})" unless @config.debug
      @history.add_message(
        role: "user",
        content: "You MUST call a tool. Do not respond with text. Call search, read, bash, or done tool now."
      )
    end

    def handle_max_tool_calls(content, total_tool_calls)
      error_msg = "⚠️  Reached maximum tool calls (#{MAX_TOOL_CALLS}). Stopping to prevent excessive operations."
      puts "\n#{error_msg}\n"
      @history.add_message(role: "assistant", content: error_msg)
      content.empty? ? error_msg : content
    end

    def execute_tool_calls(tool_calls, iteration)
      puts "\n🤖 Iteration #{iteration}: Calling #{tool_calls.length} tool(s)..." unless @config.debug

      done_result = nil
      tool_calls.each do |tool_call|
        result = execute_tool(tool_call)

        if tool_call.dig("function", "name") == "done"
          done_result = result
          break
        end
      end
      done_result
    end

    def finalize_response(done_result, iteration, total_tool_calls)
      puts "\n✅ Agent finished (#{iteration} iterations, #{total_tool_calls + 1} tool calls)\n" unless @config.debug
      done_result
    end

    def clear_history
      @history.clear
    end

    def execute_tool(tool_call)
      tool_name = tool_call.dig("function", "name")
      arguments = tool_call.dig("function", "arguments")

      display_tool_info(tool_name, arguments)

      params = parse_arguments(arguments)
      return nil unless params

      result = run_tool(tool_name, params)
      return nil unless result

      display_result(result) if @config.debug
      add_tool_result_to_history(tool_name, result)
      result
    rescue StandardError => e
      handle_tool_error(e)
    end

    def display_tool_info(tool_name, arguments)
      if @config.debug
        puts "\n🔧 Tool: #{tool_name}"
        puts "   Args: #{arguments.inspect}"
      else
        display_minimal_tool_info(tool_name, arguments)
      end
    end

    def display_minimal_tool_info(tool_name, arguments)
      icon_and_key = {
        "bash" => ["💻", "command"],
        "read" => ["📖", "file_path"],
        "search" => ["🔍", "pattern"]
      }

      return unless icon_and_key.key?(tool_name)

      icon, key = icon_and_key[tool_name]
      value = arguments.is_a?(Hash) ? arguments[key] : JSON.parse(arguments)[key]
      puts "   #{icon} #{value}"
    rescue JSON::ParserError
      nil
    end

    def parse_arguments(arguments)
      arguments.is_a?(Hash) ? arguments : JSON.parse(arguments)
    rescue JSON::ParserError => e
      error_msg = "Error parsing tool arguments: #{e.message}"
      puts "   ✗ #{error_msg}"
      @history.add_message(role: "user", content: error_msg)
      nil
    end

    def run_tool(tool_name, params)
      context = { root_path: @config.root_path }
      Tools.execute(tool_name: tool_name, params: params, context: context)
    rescue StandardError => e
      error_msg = "Error executing tool: #{e.message}"
      puts "   ✗ #{error_msg}"
      @history.add_message(role: "user", content: error_msg)
      nil
    end

    def display_result(result)
      first_line = result.lines.first&.strip || "(empty)"
      suffix = result.lines.count > 1 ? "... (#{result.lines.count} lines)" : ""
      puts "   ✓ Result: #{first_line}#{suffix}"
    end

    def add_tool_result_to_history(tool_name, result)
      @history.add_message(role: "user", content: "Tool '#{tool_name}' result:\n#{result}")
    end

    def handle_tool_error(error)
      error_msg = "Error: #{error.message}"
      puts "   ✗ #{error_msg}"
      @history.add_message(role: "user", content: error_msg)
      nil
    end

    def build_adapter
      case @config.adapter
      when :ollama
        Adapters::Ollama.new(@config)
      else
        raise "Unknown Adapter"
      end
    end

    def build_system_prompt
      context = ContextBuilder.new(root_path: @config.root_path).environment_context

      <<~PROMPT.strip
        You are a helpful Ruby on Rails coding assistant.

        #{context}

        # CRITICAL RULE
        You MUST call a tool in EVERY response. You MUST NEVER respond with just text.

        # Available tools
        - bash: explore directories (ls, find)
        - search: find text inside files (supports case_insensitive parameter)
        - read: view file contents with line numbers
        - done: call this when you have the answer (with your final answer as the parameter)

        # Required workflow
        1. Call search with the pattern
        2. If "No matches found" → call search again with case_insensitive: true
        3. If still no matches → call search with simpler pattern
        4. Once found → call read to see the file
        5. Once you have the answer → call done with your final answer

        IMPORTANT: You cannot respond with plain text. You must ALWAYS call one of the tools.
        When you're ready to provide your answer, call the "done" tool with your answer as the parameter.
      PROMPT
    end
  end
end
