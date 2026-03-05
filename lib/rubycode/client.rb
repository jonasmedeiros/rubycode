# frozen_string_literal: true

require "set"

module RubyCode
  # Main client that provides the public API for the agent
  class Client
    attr_reader :history

    def initialize(tty_prompt: nil)
      @config = RubyCode.config
      @adapter = build_adapter
      @history = History.new
      @read_files = Set.new
      @tty_prompt = tty_prompt
    end

    def ask(prompt:)
      @history.add_message(role: "user", content: prompt)
      system_prompt = build_system_prompt

      AgentLoop.new(
        adapter: @adapter,
        history: @history,
        config: @config,
        system_prompt: system_prompt,
        options: { read_files: @read_files, tty_prompt: @tty_prompt }
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
      instructions = load_system_prompt

      [
        instructions,
        "",
        context
      ].join("\n")
    end

    def load_system_prompt
      prompt_path = File.join(__dir__, "..", "..", "config", "system_prompt.md")
      File.read(prompt_path)
    end
  end
end
