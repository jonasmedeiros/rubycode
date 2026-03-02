# frozen_string_literal: true

require "English"
require "shellwords"

module RubyCode
  module Tools
    # Tool for executing safe bash commands
    class Bash < Base
      # Whitelist of safe commands
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

      DESCRIPTION = "Execute safe bash commands for exploring the filesystem and terminal operations.\n\n" \
                    "Use this for any command-line operations including:\n" \
                    "- Directory exploration: ls, find, tree\n" \
                    "- File inspection: cat, head, tail, wc, file\n" \
                    "- Content search: grep, rg (ripgrep)\n\n" \
                    "Examples:\n" \
                    "- grep -rn 'button' app/views\n" \
                    "- find . -name '*.rb' -type f\n" \
                    "- ls -la app/\n\n" \
                    "Whitelisted commands: #{SAFE_COMMANDS.join(", ")}".freeze

      SCHEMA = {
        type: "function",
        function: {
          name: "bash",
          description: DESCRIPTION,
          parameters: {
            type: "object",
            properties: {
              command: {
                type: "string",
                description: "The bash command to execute. Examples:\n" \
                             "- 'grep -rn \"button\" app/views' (search for text in files)\n" \
                             "- 'find . -name \"*.rb\"' (find files by name)\n" \
                             "- 'ls -la app/' (list directory contents)"
              }
            },
            required: ["command"]
          }
        }
      }.freeze

      def self.definition
        SCHEMA
      end

      private

      def perform(params)
        command = params["command"].strip
        base_command = command.split.first

        raise UnsafeCommandError, safe_command_error(base_command) unless SAFE_COMMANDS.include?(base_command)

        execute_command(command)
      end

      def safe_command_error(base_command)
        "Command '#{base_command}' is not allowed. Safe commands: #{SAFE_COMMANDS.join(", ")}"
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
