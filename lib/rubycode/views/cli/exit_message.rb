# frozen_string_literal: true

require "pastel"

module RubyCode
  module Views
    module Cli
      # Builds goodbye/exit message
      class ExitMessage
        def self.build
          pastel = Pastel.new
          "\n#{pastel.green("Goodbye!")}\n"
        end
      end
    end
  end
end
