# frozen_string_literal: true

require "pastel"

module RubyCode
  module Views
    module Cli
      # Builds auto-approve disabled message
      class AutoApproveDisabled
        def self.build
          pastel = Pastel.new
          "\n#{pastel.green("✓")} Auto-approve disabled\n" \
            "You will be prompted before file operations.\n\n"
        end
      end
    end
  end
end
