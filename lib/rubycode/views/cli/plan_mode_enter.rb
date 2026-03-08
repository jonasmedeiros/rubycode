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
            "Next: Describe what you want to explore and implement.\n" \
            "The AI will explore the codebase, present a plan, and ask for your approval.\n\n"
        end
      end
    end
  end
end
