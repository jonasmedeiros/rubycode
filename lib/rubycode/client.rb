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
      # Add user message to history
      @history.add_message(role: "user", content: prompt)

      # Build system prompt with environment context
      system_prompt = build_system_prompt

      iteration = 0
      total_tool_calls = 0

      # Agent loop: keep calling LLM until no more tool calls
      loop do
        iteration += 1

        # Check iteration limit
        if iteration > MAX_ITERATIONS
          error_msg = "⚠️  Reached maximum iterations (#{MAX_ITERATIONS}). The agent may be stuck in a loop."
          puts "\n#{error_msg}\n"
          @history.add_message(role: "assistant", content: error_msg)
          return error_msg
        end

        # Get messages in LLM format
        messages = @history.to_llm_format

        # Get response from LLM with tools
        response_body = @adapter.generate(
          messages: messages,
          system: system_prompt,
          tools: Tools.definitions
        )

        # Extract assistant message
        assistant_message = response_body["message"]
        content = assistant_message["content"] || ""
        tool_calls = assistant_message["tool_calls"] || []

        # Add assistant response to history
        @history.add_message(role: "assistant", content: content)

        # If no tool calls, we're done
        if tool_calls.empty?
          # ============================================================================
          # WORKAROUND FOR WEAK TOOL-CALLING MODELS (e.g., qwen3-coder)
          # This is ONLY for testing with models that have poor tool-calling capabilities.
          # OpenCode does NOT do this - they rely on good models (Claude, GPT-4).
          # Enable with: config.enable_tool_injection_workaround = true
          # ============================================================================
          if @config.enable_tool_injection_workaround && iteration < 10
            puts "   ⚠️  No tool calls - injecting reminder (iteration #{iteration})" unless @config.debug

            @history.add_message(
              role: "user",
              content: "You MUST call a tool. Do not respond with text. Call search, read, bash, or done tool now."
            )
            next  # Continue the loop
          end
          # ============================================================================
          # END WORKAROUND
          # ============================================================================

          puts "\n✅ Agent finished (#{iteration} iterations, #{total_tool_calls} tool calls)\n" unless @config.debug
          return content
        end

        # Check tool call limit
        total_tool_calls += tool_calls.length
        if total_tool_calls > MAX_TOOL_CALLS
          error_msg = "⚠️  Reached maximum tool calls (#{MAX_TOOL_CALLS}). Stopping to prevent excessive operations."
          puts "\n#{error_msg}\n"
          @history.add_message(role: "assistant", content: error_msg)
          return content.empty? ? error_msg : content
        end

        # Execute each tool call
        unless @config.debug
          puts "\n🤖 Iteration #{iteration}: Calling #{tool_calls.length} tool(s)..."
        end

        done_result = nil
        tool_calls.each do |tool_call|
          result = execute_tool(tool_call)

          # Check if this was the "done" tool
          if tool_call.dig("function", "name") == "done"
            done_result = result
            break
          end
        end

        # If done was called, return the result
        if done_result
          puts "\n✅ Agent finished (#{iteration} iterations, #{total_tool_calls + 1} tool calls)\n" unless @config.debug
          return done_result
        end

        # Loop continues - send tool results back to LLM
      end
    end

    private

    def clear_history
      @history.clear
    end

    private

    def execute_tool(tool_call)
      tool_name = tool_call.dig("function", "name")
      arguments = tool_call.dig("function", "arguments")

      if @config.debug
        puts "\n🔧 Tool: #{tool_name}"
        puts "   Args: #{arguments.inspect}"
      else
        # Show minimal output
        case tool_name
        when "bash"
          cmd = arguments.is_a?(Hash) ? arguments["command"] : JSON.parse(arguments)["command"]
          puts "   💻 #{cmd}"
        when "read"
          file = arguments.is_a?(Hash) ? arguments["file_path"] : JSON.parse(arguments)["file_path"]
          puts "   📖 #{file}"
        when "search"
          pattern = arguments.is_a?(Hash) ? arguments["pattern"] : JSON.parse(arguments)["pattern"]
          puts "   🔍 #{pattern}"
        end
      end

      begin
        # Arguments might be Hash or JSON string
        params = arguments.is_a?(Hash) ? arguments : JSON.parse(arguments)

        # Execute the tool
        context = { root_path: @config.root_path }
        result = Tools.execute(
          tool_name: tool_name,
          params: params,
          context: context
        )

        if @config.debug
          puts "   ✓ Result: #{result.lines.first&.strip || '(empty)'}#{result.lines.count > 1 ? "... (#{result.lines.count} lines)" : ""}"
        end

        # Add tool result to history
        @history.add_message(
          role: "user",
          content: "Tool '#{tool_name}' result:\n#{result}"
        )

        # Return the result so caller can check if it was "done"
        result

      rescue JSON::ParserError => e
        error_msg = "Error parsing tool arguments: #{e.message}"
        puts "   ✗ #{error_msg}"
        @history.add_message(role: "user", content: error_msg)
        nil
      rescue => e
        error_msg = "Error executing tool: #{e.message}"
        puts "   ✗ #{error_msg}"
        @history.add_message(role: "user", content: error_msg)
        nil
      end
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
