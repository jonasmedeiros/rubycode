# frozen_string_literal: true

require "English"
require "shellwords"

module Rubycode
  module Tools
    class Bash
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
      ].freeze

      def self.definition
        {
          type: "function",
          function: {
            name: "bash",
            description: "Execute safe bash commands for exploring the filesystem and terminal operations.\n\nIMPORTANT: This tool is for terminal operations and directory exploration (ls, find, tree, etc.). DO NOT use it for file operations (reading, searching file contents) - use the specialized tools instead.\n\nWhitelisted commands: #{SAFE_COMMANDS.join(", ")}",
            parameters: {
              type: "object",
              properties: {
                command: {
                  type: "string",
                  description: "The bash command to execute (e.g., 'ls -la', 'find . -name \"*.rb\"', 'tree app')"
                }
              },
              required: ["command"]
            }
          }
        }
      end

      def self.execute(params:, context:)
        command = params["command"].strip
        base_command = command.split.first

        return safe_command_error(base_command) unless SAFE_COMMANDS.include?(base_command)

        run_command(command, context[:root_path])
      rescue StandardError => e
        "Error executing command: #{e.message}"
      end

      def self.safe_command_error(base_command)
        "Error: Command '#{base_command}' is not allowed. Safe commands: #{SAFE_COMMANDS.join(", ")}"
      end

      def self.run_command(command, root_path)
        Dir.chdir(root_path) do
          output = `#{command} 2>&1`
          exit_code = $CHILD_STATUS.exitstatus

          exit_code.zero? ? truncate_output(output) : command_error(exit_code, output)
        end
      end

      def self.truncate_output(output)
        lines = output.split("\n")
        return output if lines.length <= 200

        lines[0..199].join("\n") + "\n\n... (#{lines.length - 200} more lines truncated)"
      end

      def self.command_error(exit_code, output)
        "Command failed with exit code #{exit_code}:\n#{output}"
      end
    end
  end
end
