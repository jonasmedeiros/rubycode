# frozen_string_literal: true

require "pastel"

module RubyCode
  module Views
    # Builds file write approval prompt display
    class WriteApproval
      def self.build(file_path:, content:)
        pastel = Pastel.new

        [
          "",
          header_section(pastel),
          file_info_section(pastel, file_path, content),
          pastel.yellow("─" * 80),
          preview_section(content),
          truncation_notice(pastel, content),
          pastel.yellow("━" * 80)
        ].compact.join("\n")
      end

      def self.header_section(pastel)
        [pastel.yellow("━" * 80), pastel.bold("Write Operation - Approval Required")].join("\n")
      end

      def self.file_info_section(pastel, file_path, content)
        ["#{pastel.cyan("File:")} #{file_path}", "#{pastel.cyan("Lines:")} #{content.lines.count}"].join("\n")
      end

      def self.preview_section(content)
        content.lines.first(20).join
      end

      def self.truncation_notice(pastel, content)
        return "" unless content.lines.count > 20

        pastel.dim("... (#{content.lines.count - 20} more lines)")
      end
    end
  end
end
