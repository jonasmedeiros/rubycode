# frozen_string_literal: true

require "pastel"

module RubyCode
  module Views
    class Welcome
      def self.build
        pastel = Pastel.new
        TTY::Box.frame(
          width: 80,
          border: :thick,
          title: { top_left: " RubyCode v#{RubyCode::VERSION} " }
        ) do
          [
            pastel.bold.cyan("AI Ruby/Rails Code Assistant"),
            "",
            "Built with: #{pastel.dim("Ollama + DeepSeek + TTY Toolkit")}",
            pastel.dim("─" * 76),
            "#{pastel.yellow("Commands:")} exit, quit, clear"
          ].join("\n")
        end
      end
    end
  end
end
