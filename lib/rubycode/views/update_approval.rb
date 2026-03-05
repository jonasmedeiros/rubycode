# frozen_string_literal: true

require "pastel"

module RubyCode
  module Views
    # Builds file update approval prompt display with diff
    class UpdateApproval
      def self.build(file_path:, old_string:, new_string:)
        pastel = Pastel.new

        old_lines = old_string.lines.map { |line| pastel.red("  - #{line.chomp}") }
        new_lines = new_string.lines.map { |line| pastel.green("  + #{line.chomp}") }

        [
          "",
          pastel.yellow("━" * 80),
          pastel.bold("Update Operation - Approval Required"),
          "#{pastel.cyan("File:")} #{file_path}",
          pastel.yellow("─" * 80),
          pastel.red("- REMOVE:"),
          old_lines.join("\n"),
          "",
          pastel.green("+ ADD:"),
          new_lines.join("\n"),
          pastel.yellow("━" * 80)
        ].join("\n")
      end
    end
  end
end
