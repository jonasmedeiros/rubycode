# frozen_string_literal: true

require "pastel"

module RubyCode
  module Views
    module Cli
      # Builds auto-approve enabled message
      class AutoApproveEnabled
        def self.build
          pastel = Pastel.new
          "\n#{pastel.green("✓")} Auto-approve enabled for write and update operations\n" \
            "#{pastel.yellow("⚠")} Files will be modified without confirmation.\n" \
            "Use 'auto-approve off' to disable.\n\n"
        end
      end
    end
  end
end
