# frozen_string_literal: true

require "pastel"

module RubyCode
  module Views
    # Builds file write approval prompt display
    class WriteApproval
      def self.build(file_path:, content:)
        pastel = Pastel.new
        preview_lines = content.lines.first(20)
        truncation_notice = if content.lines.count > 20
                              pastel.dim("... (#{content.lines.count - 20} more lines)")
                            else
                              ""
                            end

        [
          "",
          pastel.yellow("━" * 80),
          pastel.bold("Write Operation - Approval Required"),
          "#{pastel.cyan("File:")} #{file_path}",
          "#{pastel.cyan("Lines:")} #{content.lines.count}",
          pastel.yellow("─" * 80),
          preview_lines.join,
          truncation_notice,
          pastel.yellow("━" * 80)
        ].compact.join("\n")
      end
    end
  end
end
