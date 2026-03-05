# frozen_string_literal: true

require "pastel"

module RubyCode
  module Views
    # Builds bash command approval prompt display
    class BashApproval
      def self.build(command:, base_command:, safe_commands:)
        pastel = Pastel.new

        [
          "",
          pastel.red("━" * 80),
          pastel.bold.red("⚠ WARNING: Non-Whitelisted Command"),
          "#{pastel.cyan("Command:")} #{command}",
          "#{pastel.cyan("Base command:")} #{base_command}",
          pastel.red("─" * 80),
          pastel.yellow("This command is not in the safe whitelist:"),
          pastel.dim("Safe commands: #{safe_commands.join(", ")}"),
          "",
          pastel.yellow("⚠ Only approve if you trust this command will not cause harm"),
          pastel.red("━" * 80)
        ].join("\n")
      end
    end
  end
end
