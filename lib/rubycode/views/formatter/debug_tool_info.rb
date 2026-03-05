# frozen_string_literal: true

require "pastel"

module RubyCode
  module Views
    module Formatter
      # Builds debug mode tool information display
      class DebugToolInfo
        def self.build(tool_name:, arguments:)
          pastel = Pastel.new
          "\n#{pastel.yellow("[TOOL]")} #{tool_name}\n   #{pastel.dim("Args:")} #{arguments.inspect}"
        end
      end
    end
  end
end
