# frozen_string_literal: true

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
        include_pattern = params["include"]
        case_insensitive = params["case_insensitive"] || false

        # Resolve relative paths
        full_path = if File.absolute_path?(path)
                      path
                    else
                      File.join(context[:root_path], path)
                    end

        unless File.exist?(full_path)
          return "Error: Path '#{path}' does not exist"
        end

        # Build grep command safely using Shellwords to prevent injection
        cmd_parts = ["grep", "-n", "-r"]
        cmd_parts << "-i" if case_insensitive
        cmd_parts << "--include=#{Shellwords.escape(include_pattern)}" if include_pattern
        cmd_parts << Shellwords.escape(pattern)
        cmd_parts << Shellwords.escape(full_path)

        command = cmd_parts.join(" ")

        output = `#{command} 2>&1`
        exit_code = $?.exitstatus

        if exit_code == 0
          # Found matches
          lines = output.split("\n")
          if lines.length > 100
            lines[0..99].join("\n") + "\n\n... (#{lines.length - 100} more matches truncated)"
          else
            output
          end
        elsif exit_code == 1
          # No matches found
          "No matches found for pattern: #{pattern}"
        else
          # Error occurred
          "Error running search: #{output}"
        end
      rescue => e
        "Error: #{e.message}"
      end
    end
  end
end
