# frozen_string_literal: true

require "pastel"

module RubyCode
  module Views
    # Builds file update approval prompt display with diff
    class UpdateApproval
      def self.build(file_path:, old_string:, new_string:)
        pastel = Pastel.new

        [
          "",
          pastel.yellow("━" * 80),
          pastel.bold("Update Operation - Approval Required"),
          "#{pastel.cyan("File:")} #{file_path}",
          pastel.yellow("─" * 80),
          format_removal_section(pastel, old_string),
          "",
          format_addition_section(pastel, new_string),
          pastel.yellow("━" * 80)
        ].join("\n")
      end

      def self.format_removal_section(pastel, old_string)
        old_lines = old_string.lines.map { |line| pastel.red("  - #{line.chomp}") }
        [pastel.red("- REMOVE:"), old_lines.join("\n")].join("\n")
      end

      def self.format_addition_section(pastel, new_string)
        new_lines = new_string.lines.map { |line| pastel.green("  + #{line.chomp}") }
        [pastel.green("+ ADD:"), new_lines.join("\n")].join("\n")
      end
    end
  end
end
