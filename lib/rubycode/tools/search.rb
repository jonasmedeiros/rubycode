# frozen_string_literal: true

require "English"
require "shellwords"

module Rubycode
  module Tools
    class Search
      def self.definition
        {
          type: "function",
          function: {
            name: "search",
            description: "Search INSIDE file contents for patterns using grep. Returns matching lines with file paths and line numbers.\n\n- Searches file CONTENTS using regular expressions\n- Use this when you need to find WHERE specific text/code appears inside files\n- Returns file paths, line numbers, and the matching content\n- Example: search for 'button' to find files containing that text",
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
        }
      end

      def self.execute(params:, context:)
        pattern = params["pattern"]
        path = params["path"] || "."

        full_path = resolve_path(path, context[:root_path])
        return "Error: Path '#{path}' does not exist" unless File.exist?(full_path)

        command = build_grep_command(pattern, full_path, params)
        output, exit_code = run_command(command)

        format_output(output, exit_code, pattern)
      rescue StandardError => e
        "Error: #{e.message}"
      end

      def self.resolve_path(path, root_path)
        File.absolute_path?(path) ? path : File.join(root_path, path)
      end

      def self.build_grep_command(pattern, full_path, params)
        cmd_parts = ["grep", "-n", "-r"]
        cmd_parts << "-i" if params["case_insensitive"]
        cmd_parts << "--include=#{Shellwords.escape(params["include"])}" if params["include"]
        cmd_parts << Shellwords.escape(pattern)
        cmd_parts << Shellwords.escape(full_path)
        cmd_parts.join(" ")
      end

      def self.run_command(command)
        output = `#{command} 2>&1`
        [output, $CHILD_STATUS.exitstatus]
      end

      def self.format_output(output, exit_code, pattern)
        case exit_code
        when 0
          truncate_output(output)
        when 1
          "No matches found for pattern: #{pattern}"
        else
          "Error running search: #{output}"
        end
      end

      def self.truncate_output(output)
        lines = output.split("\n")
        return output if lines.length <= 100

        lines[0..99].join("\n") + "\n\n... (#{lines.length - 100} more matches truncated)"
      end
    end
  end
end
