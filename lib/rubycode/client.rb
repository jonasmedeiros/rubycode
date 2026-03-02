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
        - bash: run any safe command (ls, find, grep, cat, etc.)
        - search: simplified search (use bash + grep for more control)
        - read: view file contents with line numbers
        - done: call when you have the answer

        # Recommended workflow
        1. Use bash with grep to search: `grep -rn "pattern" directory/`
        2. Use bash with find to locate files: `find . -name "*.rb"`
        3. Once found → use read to see the file
        4. When ready → call done with your final answer

        # Example searches
        - `grep -rn "button" app/views` - search for "button" in views
        - `grep -ri "new product" .` - case-insensitive search
        - `find . -name "*product*"` - find files with "product" in name

        IMPORTANT: You cannot respond with plain text. You must ALWAYS call one of the tools.
        When you're ready to provide your answer, call the "done" tool with your answer as the parameter.
      PROMPT
    end
  end
end
