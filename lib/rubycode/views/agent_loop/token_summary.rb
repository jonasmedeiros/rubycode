# frozen_string_literal: true

module RubyCode
  module Views
    module AgentLoop
      # Displays token usage and cost information
      class TokenSummary
        def self.build(tokens:, adapter:, model:, cumulative: nil)
          pastel = Pastel.new
          cost = Pricing.calculate_cost(adapter: adapter, model: model, tokens: tokens)

          lines = build_token_lines(tokens, cost, pastel)
          lines.concat(build_cumulative_lines(cumulative, adapter, model, pastel)) if cumulative

          lines.join("\n")
        end

        def self.build_token_lines(tokens, cost, pastel)
          lines = [""]
          lines << build_tokens_line(tokens, pastel)
          lines << build_thinking_line(tokens, pastel) if tokens.thinking&.positive?
          lines << build_cached_line(tokens, pastel) if tokens.cached&.positive?
          lines << build_cost_line(cost, pastel)
          lines
        end

        def self.build_tokens_line(tokens, pastel)
          "   #{pastel.dim("Tokens:")} " \
            "#{pastel.cyan(tokens.input.to_s)} in / " \
            "#{pastel.cyan(tokens.output.to_s)} out"
        end

        def self.build_thinking_line(tokens, pastel)
          "   #{pastel.dim("Thinking:")} #{pastel.yellow(tokens.thinking.to_s)} tokens"
        end

        def self.build_cached_line(tokens, pastel)
          "   #{pastel.dim("Cached:")} #{pastel.green(tokens.cached.to_s)} tokens (cost saved)"
        end

        def self.build_cost_line(cost, pastel)
          "   #{pastel.dim("Cost:")} #{pastel.bold(Pricing.format_cost(cost))}"
        end

        def self.build_cumulative_lines(cumulative, adapter, model, pastel)
          total_cost = Pricing.calculate_cost(adapter: adapter, model: model, tokens: cumulative)
          ["   #{pastel.dim("Session total:")} " \
           "#{pastel.cyan(cumulative.total.to_s)} tokens / " \
           "#{pastel.bold(Pricing.format_cost(total_cost))}"]
        end
      end
    end
  end
end
