# frozen_string_literal: true

require "pastel"

module RubyCode
  module Views
    module Cli
      # Builds plan mode exit message
      class PlanModeExit
        def self.build
          pastel = Pastel.new
          "\n#{pastel.green("✓")} Plan Mode complete. Returning to normal mode.\n\n"
        end
      end
    end
  end
end
