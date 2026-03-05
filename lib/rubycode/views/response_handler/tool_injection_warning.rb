# frozen_string_literal: true

require "pastel"

module RubyCode
  module Views
    module ResponseHandler
      # Builds tool injection warning message
      class ToolInjectionWarning
        def self.build(iteration:)
          pastel = Pastel.new
          "   #{pastel.yellow("[WARNING]")} No tool calls - injecting reminder (iteration #{iteration})"
        end
      end
    end
  end
end
