# frozen_string_literal: true

require "pastel"

module RubyCode
  module Views
    module Cli
      # Builds error display with backtrace
      class ErrorDisplay
        def self.build(error:)
          pastel = Pastel.new
          backtrace_preview = error.backtrace.first(3).join("\n")

          "\n#{pastel.red("[ERROR]")} #{error.message}\n#{pastel.dim(backtrace_preview)}"
        end
      end
    end
  end
end
