# frozen_string_literal: true

require "pastel"

module RubyCode
  module Views
    module AgentLoop
      # Builds response received status
      class ResponseReceived
        def self.build
          pastel = Pastel.new
          "#{pastel.green("✓")} Response received"
        end
      end
    end
  end
end
