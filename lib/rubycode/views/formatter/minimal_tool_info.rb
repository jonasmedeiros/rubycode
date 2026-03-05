# frozen_string_literal: true

require "pastel"
require "tty-table"

module RubyCode
  module Views
    module Formatter
      # Builds minimal tool info table display
      class MinimalToolInfo
        def self.build(label:, value:)
          pastel = Pastel.new

          table = TTY::Table.new(rows: [
                                   [
                                     pastel.cyan(label),
                                     value
                                   ]
                                 ])

          "  #{table.render(:basic, padding: [0, 1])}"
        end
      end
    end
  end
end
