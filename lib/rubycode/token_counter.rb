# frozen_string_literal: true

module RubyCode
  # Tracks token usage across LLM requests
  class TokenCounter
    attr_reader :input, :output, :cached, :cache_creation, :thinking

    def initialize(input: 0, output: 0, cached: 0, cache_creation: 0, thinking: 0)
      @input = input || 0
      @output = output || 0
      @cached = cached || 0
      @cache_creation = cache_creation || 0
      @thinking = thinking || 0
    end

    def total
      input + output + thinking
    end

    def to_h
      {
        input_tokens: input,
        output_tokens: output,
        cached_tokens: cached,
        cache_creation_tokens: cache_creation,
        thinking_tokens: thinking,
        total_tokens: total
      }.compact
    end

    def +(other)
      TokenCounter.new(
        input: input + other.input,
        output: output + other.output,
        cached: cached + other.cached,
        cache_creation: cache_creation + other.cache_creation,
        thinking: thinking + other.thinking
      )
    end
  end
end
