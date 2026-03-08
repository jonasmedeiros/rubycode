# frozen_string_literal: true

module RubyCode
  module Tools
    # Explore tool - spawns a sub-agent for autonomous codebase exploration
    class Explore < Base
      def perform(params)
        query = params["query"]
        max_iterations = params["max_iterations"] || 10

        # Build a fresh adapter for the sub-agent
        adapter = build_adapter

        # Create explorer and run
        explorer = Explorer.new(
          adapter: adapter,
          config: context[:config] || RubyCode.config,
          query: query,
          max_iterations: max_iterations
        )

        explorer.explore

        # Return the exploration result
      end

      private

      def build_adapter
        config = context[:config] || RubyCode.config

        case config.adapter
        when :ollama
          Adapters::Ollama.new(config)
        when :openrouter
          Adapters::Openrouter.new(config)
        when :deepseek
          Adapters::Deepseek.new(config)
        when :gemini
          Adapters::Gemini.new(config)
        when :openai
          Adapters::Openai.new(config)
        else
          raise ToolError, "Unknown adapter: #{config.adapter}"
        end
      end
    end
  end
end
