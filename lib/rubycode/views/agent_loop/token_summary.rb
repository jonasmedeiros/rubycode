# frozen_string_literal: true

module RubyCode
  module Views
    module AgentLoop
      # Displays token usage and cost information
      class TokenSummary
        def self.build(tokens:, adapter:, model:, cumulative: nil)
          pastel = Pastel.new
          cost = Pricing.calculate_cost(adapter: adapter, model: model, tokens: tokens)

          lines = []
          lines << ""
          lines << "   #{pastel.dim("Tokens:")} " \
                   "#{pastel.cyan(tokens.input.to_s)} in / " \
                   "#{pastel.cyan(tokens.output.to_s)} out"

          if tokens.thinking&.positive?
            lines << "   #{pastel.dim("Thinking:")} #{pastel.yellow(tokens.thinking.to_s)} tokens"
          end

          if tokens.cached&.positive?
            lines << "   #{pastel.dim("Cached:")} #{pastel.green(tokens.cached.to_s)} tokens (cost saved)"
          end

          lines << "   #{pastel.dim("Cost:")} #{pastel.bold(Pricing.format_cost(cost))}"

          if cumulative
            total_cost = Pricing.calculate_cost(adapter: adapter, model: model, tokens: cumulative)
            lines << "   #{pastel.dim("Session total:")} " \
                     "#{pastel.cyan(cumulative.total.to_s)} tokens / " \
                     "#{pastel.bold(Pricing.format_cost(total_cost))}"
          end

          lines.join("\n")
        end
      end
    end
  end
end
