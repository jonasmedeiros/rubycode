# frozen_string_literal: true

require "pastel"

module RubyCode
  module Views
    module Cli
      # Builds plan mode entry message
      class PlanModeEnter
        def self.build
          pastel = Pastel.new
          "\n#{pastel.cyan("📋")} Entering Plan Mode\n" \
            "Next: Describe your task (e.g., 'add user authentication').\n" \
            "AI will: 1) Explore codebase  2) Show findings  3) Ask approval  4) Implement if approved\n\n"
        end
      end
    end
  end
end
