# frozen_string_literal: true

require "pastel"

module RubyCode
  module Views
    # Builds skip notification display
    class SkipNotification
      def self.build(message:)
        pastel = Pastel.new
        pastel.yellow("   ⓘ Skipped: #{message}")
      end
    end
  end
end
