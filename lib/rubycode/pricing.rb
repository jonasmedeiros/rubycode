# frozen_string_literal: true

module RubyCode
  # Calculates cost estimates based on provider pricing
  module Pricing
    # Prices per 1M tokens (as of March 2026)
    RATES = {
      gemini: {
        "gemini-2.5-flash" => { input: 0.0375, output: 0.15, cached: 0.01 },
        "gemini-2.5-pro" => { input: 1.25, output: 5.00, cached: 0.31 },
        "gemini-3-flash-preview" => { input: 0.0375, output: 0.15, cached: 0.01 }
      },
      openai: {
        "gpt-4o" => { input: 2.50, output: 10.00, cached: 1.25 },
        "gpt-4o-mini" => { input: 0.15, output: 0.60, cached: 0.075 },
        "o1" => { input: 15.00, output: 60.00 }
      },
      deepseek: {
        "deepseek-chat" => { input: 0.14, output: 0.28, cached: 0.014 },
        "deepseek-reasoner" => { input: 0.55, output: 2.19, cached: 0.014 }
      },
      openrouter: {
        "anthropic/claude-sonnet-4.5" => { input: 3.00, output: 15.00, cached: 0.30 },
        "anthropic/claude-opus-4.6" => { input: 15.00, output: 75.00, cached: 1.50 }
      },
      ollama: {
        "default" => { input: 0.0, output: 0.0 }
      }
    }.freeze

    def self.calculate_cost(adapter:, model:, tokens:)
      rates = RATES.dig(adapter.to_sym, model) || RATES.dig(adapter.to_sym, "default")
      return 0.0 unless rates

      input_cost = (tokens.input / 1_000_000.0) * rates[:input]
      output_cost = (tokens.output / 1_000_000.0) * rates[:output]
      cached_cost = (tokens.cached / 1_000_000.0) * (rates[:cached] || 0)

      input_cost + output_cost - cached_cost # Cached reduces cost
    end

    def self.format_cost(cost_usd)
      if cost_usd < 0.01
        cents = (cost_usd * 100).round(4)
        "$#{cents}¢"
      else
        "$#{cost_usd.round(4)}"
      end
    end
  end
end
