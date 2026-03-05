# frozen_string_literal: true

require "pastel"

module RubyCode
  module Views
    module Cli
      # Builds history cleared confirmation message
      class HistoryClearedMessage
        def self.build
          pastel = Pastel.new
          "#{pastel.yellow("✓")} History cleared!"
        end
      end
    end
  end
end
