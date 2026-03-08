# frozen_string_literal: true

require "pastel"
require "tty-table"

module RubyCode
  module Views
    module Cli
      # Builds configuration table display
      class ConfigurationTable
        def self.build(directory:, model:, adapter: :ollama)
          pastel = Pastel.new

          table = TTY::Table.new(
            header: [pastel.bold("Setting"), pastel.bold("Value")],
            rows: [
              ["Adapter", adapter.to_s.capitalize],
              ["Model", model],
              ["Directory", directory]
            ]
          )

          "\n#{table.render(:unicode, padding: [0, 1])}"
        end
      end
    end
  end
end
