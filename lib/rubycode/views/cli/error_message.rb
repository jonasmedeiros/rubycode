# frozen_string_literal: true

require "pastel"

module RubyCode
  module Views
    module Cli
      # Builds error message display
      class ErrorMessage
        def self.build(message:)
          pastel = Pastel.new
          "\n#{pastel.red("[ERROR]")} #{message}"
        end
      end
    end
  end
end
