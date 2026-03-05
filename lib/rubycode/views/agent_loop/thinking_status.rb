# frozen_string_literal: true

require "pastel"

module RubyCode
  module Views
    module AgentLoop
      # Builds thinking status indicator
      class ThinkingStatus
        def self.build
          pastel = Pastel.new
          "#{pastel.dim("→")} Thinking..."
        end
      end
    end
  end
end
