# frozen_string_literal: true

module RubyCode
  # Main client that provides the public API for the agent
  class Client
    attr_reader :history

    def initialize
      @config = RubyCode.config
      @adapter = build_adapter
      @history = History.new
    end

    def ask(prompt:)
      @history.add_message(role: "user", content: prompt)
      system_prompt = build_system_prompt

      AgentLoop.new(
        adapter: @adapter,
        history: @history,
        config: @config,
        system_prompt: system_prompt
      ).run
    end

    def clear_history
      @history.clear
    end

    private

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

      <<~PROMPT
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
