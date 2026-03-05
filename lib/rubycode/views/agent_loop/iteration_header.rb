# frozen_string_literal: true

require "pastel"

module RubyCode
  module Views
    module AgentLoop
      # Builds iteration header with tool list
      class IterationHeader
        def self.build(iteration:, tool_calls:)
          pastel = Pastel.new

          header = pastel.cyan("┌─ Iteration #{iteration} ─────────────────────────")
          tool_list = tool_calls.each_with_index.map do |tool_call, idx|
            tool_name = tool_call.dig("function", "name")
            "  #{pastel.dim("#{idx + 1}.")} #{tool_name}"
          end

          [header, *tool_list].join("\n")
        end
      end
    end
  end
end
