# frozen_string_literal: true

require "set"

module RubyCode
  # Main client that provides the public API for the agent
  class Client
    attr_reader :memory

    def initialize(tty_prompt: nil)
      @config = RubyCode.config
      @adapter = build_adapter
      @memory = Memory.new
      @memory.clear # Clear memory at start of each session to prevent payload size issues
      @read_files = Set.new
      @tty_prompt = tty_prompt
    end

    def ask(prompt:)
      @memory.add_message(role: "user", content: prompt)
      system_prompt = build_system_prompt

      AgentLoop.new(
        adapter: @adapter,
        memory: @memory,
        config: @config,
        system_prompt: system_prompt,
        options: { read_files: @read_files, tty_prompt: @tty_prompt }
      ).run
    end

    def clear_memory
      @memory.clear
      @read_files.clear
    end

    private

    def build_adapter
      case @config.adapter
      when :ollama
        Adapters::Ollama.new(@config)
      when :openrouter
        Adapters::Openrouter.new(@config)
      when :deepseek
        Adapters::Deepseek.new(@config)
      when :gemini
        Adapters::Gemini.new(@config)
      when :openai
        Adapters::Openai.new(@config)
      else
        raise I18n.t("rubycode.errors.unknown_adapter")
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
