# frozen_string_literal: true

require "English"
require "shellwords"

module RubyCode
  module Tools
    # Tool for searching file contents with grep
    class Search < Base
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
