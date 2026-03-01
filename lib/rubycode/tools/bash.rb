# frozen_string_literal: true

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
            description: "Execute safe bash commands for exploring the filesystem and terminal operations.\n\nIMPORTANT: This tool is for terminal operations and directory exploration (ls, find, tree, etc.). DO NOT use it for file operations (reading, searching file contents) - use the specialized tools instead.\n\nWhitelisted commands: #{SAFE_COMMANDS.join(', ')}",
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

        # Extract the base command (first word)
        base_command = command.split.first

        unless SAFE_COMMANDS.include?(base_command)
          return "Error: Command '#{base_command}' is not allowed. Safe commands: #{SAFE_COMMANDS.join(', ')}"
        end

        # Execute in the project's root directory
        Dir.chdir(context[:root_path]) do
          output = `#{command} 2>&1`
          exit_code = $?.exitstatus

          if exit_code == 0
            # Limit output length
            lines = output.split("\n")
            if lines.length > 200
              lines[0..199].join("\n") + "\n\n... (#{lines.length - 200} more lines truncated)"
            else
              output
            end
          else
            "Command failed with exit code #{exit_code}:\n#{output}"
          end
        end
      rescue => e
        "Error executing command: #{e.message}"
      end
    end
  end
end
