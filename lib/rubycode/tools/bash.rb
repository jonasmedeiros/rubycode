# frozen_string_literal: true

require "English"
require "shellwords"
require "tty-prompt"
require "pastel"

module RubyCode
  module Tools
    class Bash < Base
      SAFE_COMMANDS = %w[
        ls
        pwd
        find
        tree
        cat
        head
        tail
        wc
        file
        which
        echo
        grep
        rg
      ].freeze

      private

      def perform(params)
        command = params["command"].strip
        base_command = command.split.first

        unless SAFE_COMMANDS.include?(base_command)
          unless request_approval(command, base_command)
            raise ToolError, "USER CANCELLED: The user declined to execute '#{base_command}'. Do not retry this command. Either use a whitelisted command (#{SAFE_COMMANDS.join(", ")}) or call 'done' to finish."
          end
        end

        execute_command(command)
      end

      def request_approval(command, base_command)
        pastel = Pastel.new
        prompt = TTY::Prompt.new

        puts "\n#{pastel.red("━" * 80)}"
        puts pastel.bold.red("⚠ WARNING: Non-Whitelisted Command")
        puts "#{pastel.cyan("Command:")} #{command}"
        puts "#{pastel.cyan("Base command:")} #{base_command}"
        puts pastel.red("─" * 80)
        puts pastel.yellow("This command is not in the safe whitelist:")
        puts pastel.dim("Safe commands: #{SAFE_COMMANDS.join(", ")}")
        puts ""
        puts pastel.yellow("⚠ Only approve if you trust this command will not cause harm")
        puts pastel.red("━" * 80)

        approved = prompt.yes?("Execute this command?") do |q|
          q.default false
        end

        unless approved
          puts pastel.yellow("   ⓘ Skipped: User declined to execute '#{base_command}'")
        end

        approved
      end

      def execute_command(command)
        Dir.chdir(root_path) do
          output = `#{command} 2>&1`
          exit_code = $CHILD_STATUS.exitstatus

          raise CommandExecutionError, "Command failed with exit code #{exit_code}:\n#{output}" unless exit_code.zero?

          CommandResult.new(
            stdout: truncate_output(output),
            stderr: "",
            exit_code: exit_code
          )
        end
      end

      def truncate_output(output)
        lines = output.split("\n")
        return output if lines.length <= 200

        truncated_output = lines[0..199].join("\n")
        "#{truncated_output}\n\n... (#{lines.length - 200} more lines truncated)"
      end
    end
  end
end
