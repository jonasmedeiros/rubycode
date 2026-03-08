# frozen_string_literal: true

require "pastel"

module RubyCode
  module Views
    module Cli
      # Builds auto-approve status message
      class AutoApproveStatus
        def self.build(enabled:)
          pastel = Pastel.new
          status = enabled ? pastel.green("ENABLED") : pastel.dim("DISABLED")
          "\nAuto-approve status: #{status}\n\n"
        end
      end
    end
  end
end
