# frozen_string_literal: true

require "pastel"

module RubyCode
  module Views
    module Cli
      # Builds interrupt notification message
      class InterruptMessage
        def self.build
          pastel = Pastel.new
          "\n#{pastel.yellow("[INTERRUPTED]")} Type 'exit' to quit or continue chatting."
        end
      end
    end
  end
end
