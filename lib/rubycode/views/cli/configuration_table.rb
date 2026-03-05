# frozen_string_literal: true

require "pastel"
require "tty-table"

module RubyCode
  module Views
    module Cli
      # Builds configuration table display
      class ConfigurationTable
        def self.build(directory:, model:, debug_mode:)
          pastel = Pastel.new

          table = TTY::Table.new(
            header: [pastel.bold("Setting"), pastel.bold("Value")],
            rows: [
              ["Directory", directory],
              ["Model", model],
              ["Debug Mode", debug_mode ? pastel.green("ON") : pastel.dim("OFF")]
            ]
          )

          "\n#{table.render(:unicode, padding: [0, 1])}"
        end
      end
    end
  end
end
