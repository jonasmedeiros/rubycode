# frozen_string_literal: true

require "pastel"

module RubyCode
  module Views
    module Cli
      # Builds memory cleared confirmation message
      class MemoryClearedMessage
        def self.build
          pastel = Pastel.new
          "#{pastel.yellow("✓")} #{I18n.t("rubycode.cli.memory_cleared")}"
        end
      end
    end
  end
end
