# frozen_string_literal: true

require "English"
require "shellwords"

module RubyCode
  module Tools
    # Tool for searching file contents with grep
    class Search < Base
      SCHEMA = {
        type: "function",
        function: {
          name: "search",
          description: "Search INSIDE file contents for patterns using grep. " \
                       "Returns matching lines with file paths and line numbers.\n\n" \
                       "- Searches file CONTENTS using regular expressions\n" \
                       "- Use this when you need to find WHERE specific text/code appears inside files\n" \
                       "- Returns file paths, line numbers, and the matching content\n" \
                       "- Example: search for 'button' to find files containing that text",
          parameters: {
            type: "object",
            properties: {
              pattern: {
                type: "string",
                description: "The pattern to search for (supports regex)"
              },
              path: {
                type: "string",
                description: "Directory or file to search in. Defaults to '.' (current directory). Optional."
              },
              include: {
                type: "string",
                description: "File pattern to include (e.g., '*.rb', '*.js'). Optional."
              },
              case_insensitive: {
                type: "boolean",
                description: "Perform case-insensitive search. Optional."
              }
            },
            required: ["pattern"]
          }
        }
      }.freeze

      def self.definition
        SCHEMA
      end

      private

      def perform(params)
        pattern = params["pattern"]
        path = params["path"] || "."

        full_path = resolve_path(path)
        raise PathError, "Path '#{path}' does not exist" unless File.exist?(full_path)

        command = build_grep_command(pattern, full_path, params)
        output, exit_code = execute_grep(command)

        format_output(output, exit_code, pattern)
      end

      def resolve_path(path)
        File.absolute_path?(path) ? path : File.join(root_path, path)
      end

      def build_grep_command(pattern, full_path, params)
        [
          "grep", "-n", "-r",
          ("-i" if params["case_insensitive"]),
          ("--include=#{Shellwords.escape(params["include"])}" if params["include"]),
          Shellwords.escape(pattern),
          Shellwords.escape(full_path)
        ].compact.join(" ")
      end

      def execute_grep(command)
        output = `#{command} 2>&1`
        [output, $CHILD_STATUS.exitstatus]
      end

      def format_output(output, exit_code, pattern)
        case exit_code
        when 0
          truncate_output(output)
        when 1
          "No matches found for pattern: #{pattern}"
        else
          raise CommandExecutionError, "Error running search: #{output}"
        end
      end

      def truncate_output(output)
        lines = output.split("\n")
        return output if lines.length <= 100

        truncated = lines[0..99].join("\n")
        "#{truncated}\n\n... (#{lines.length - 100} more matches truncated)"
      end
    end
  end
end
