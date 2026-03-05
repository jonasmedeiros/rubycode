# frozen_string_literal: true

require "set"

module RubyCode
  # Main client that provides the public API for the agent
  class Client
    attr_reader :history

    def initialize
      @config = RubyCode.config
      @adapter = build_adapter
      @history = History.new
      @read_files = Set.new
    end

    def ask(prompt:)
      @history.add_message(role: "user", content: prompt)
      system_prompt = build_system_prompt

      AgentLoop.new(
        adapter: @adapter,
        history: @history,
        config: @config,
        system_prompt: system_prompt,
        read_files: @read_files
      ).run
    end

    def clear_history
      @history.clear
      @read_files.clear
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
        - bash: run commands (whitelisted commands run directly, others require user approval)
          Whitelisted: ls, pwd, find, tree, cat, head, tail, wc, file, which, echo, grep, rg
        - search: simplified search (use bash + grep for more control)
        - read: view file contents with line numbers
        - write: create new files (requires approval, errors if file exists)
        - update: modify existing files (auto-reads if needed, requires approval)
        - done: MUST call when task is complete (see below)

        # Recommended workflow
        1. Use bash with grep to search: `grep -rn "pattern" directory/`
        2. Use bash with find to locate files: `find . -name "*.rb"`
        3. Once found → use read to see the file
        4. Make changes with write/update if needed
        5. IMMEDIATELY call done when finished - do not continue exploring

        # CRITICAL: When to call 'done'
        You MUST call 'done' immediately after:
        - Completing file changes (write/update operations succeeded)
        - Answering a user's question
        - Finding the information the user requested
        - Unable to proceed (errors, file not found, etc.)

        Do NOT keep exploring after the task is done. Call 'done' right away.

        # CRITICAL: Handling user cancellations
        If you see "USER CANCELLED" in an error message:
        - The user explicitly declined that specific operation
        - Do NOT retry the exact same operation - the user has rejected it
        - Move on to other changes, or call 'done' if there's nothing else to do
        - Never get stuck in a loop retrying cancelled operations

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
