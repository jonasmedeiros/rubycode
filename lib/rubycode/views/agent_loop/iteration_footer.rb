# frozen_string_literal: true

require "pastel"

module RubyCode
  module Views
    module AgentLoop
      # Builds iteration footer
      class IterationFooter
        def self.build
          pastel = Pastel.new
          pastel.cyan("└────────────────────────────────────────────────")
        end
      end
    end
  end
end
