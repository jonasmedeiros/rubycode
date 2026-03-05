# frozen_string_literal: true

require "pastel"
require "tty-markdown"

module RubyCode
  module Views
    module Cli
      # Builds response box with markdown rendering
      class ResponseBox
        def self.build(response:)
          pastel = Pastel.new

          header = "\n#{pastel.magenta("╔═══ Agent Response ═══")}"
          footer = pastel.magenta("╚══════════════════════")

          # Try to parse as markdown, fallback to plain
          content = begin
            TTY::Markdown.parse(response, width: 80)
          rescue StandardError
            response
          end

          "#{header}\n#{content}\n#{footer}"
        end
      end
    end
  end
end
