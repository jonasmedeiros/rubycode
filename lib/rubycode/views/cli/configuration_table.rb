# frozen_string_literal: true

require "pastel"
require "tty-table"

module RubyCode
  module Views
    module Cli
      # Builds configuration table display
      class ConfigurationTable
        def self.build(directory:, model:, adapter: :ollama, debug_mode: false, auto_approve: false) # rubocop:disable Lint/UnusedMethodArgument
          pastel = Pastel.new

          rows = [
            ["Adapter", adapter.to_s.capitalize],
            ["Model", model],
            ["Directory", directory]
          ]

          # Add auto-approve status if enabled
          rows << ["Auto-approve", "#{pastel.green("ENABLED")} #{pastel.yellow("⚠")}"] if auto_approve

          table = TTY::Table.new(
            header: [pastel.bold("Setting"), pastel.bold("Value")],
            rows: rows
          )

          "\n#{table.render(:unicode, padding: [0, 1])}"
        end
      end
    end
  end
end
