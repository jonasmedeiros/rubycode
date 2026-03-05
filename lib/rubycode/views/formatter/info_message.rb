# frozen_string_literal: true

require "pastel"

module RubyCode
  module Views
    module Formatter
      # Builds info message display
      class InfoMessage
        def self.build(message:)
          pastel = Pastel.new
          "   #{pastel.dim("ℹ #{message}")}"
        end
      end
    end
  end
end
