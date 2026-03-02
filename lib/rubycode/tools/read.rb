# frozen_string_literal: true

module RubyCode
  module Tools
    # Tool for reading files and directories
    class Read < Base
      SCHEMA = {
        type: "function",
        function: {
          name: "read",
          description: "Read a file or directory from the filesystem.\n\n" \
                       "- Use this when you know the file path and want to see its contents\n" \
                       "- Returns file contents with line numbers (format: 'line_number: content')\n" \
                       "- For directories, returns a listing of entries\n" \
                       "- Use the search tool to find specific content in files\n" \
                       "- Use bash with 'ls' or 'find' to discover what files exist",
          parameters: {
            type: "object",
            properties: {
              file_path: {
                type: "string",
                description: "Absolute or relative path to the file to read"
              },
              offset: {
                type: "integer",
                description: "Line number to start reading from (1-indexed). Optional."
              },
              limit: {
                type: "integer",
                description: "Maximum number of lines to read. Default 2000. Optional."
              }
            },
            required: ["file_path"]
          }
        }
      }.freeze

      def self.definition
        SCHEMA
      end

      private

      def perform(params)
        file_path = params["file_path"]
        offset = params["offset"] || 1
        limit = params["limit"] || 2000

        full_path = resolve_path(file_path)
        raise FileNotFoundError, "File '#{file_path}' does not exist" unless File.exist?(full_path)

        return list_directory(full_path, file_path) if File.directory?(full_path)

        format_file_lines(full_path, offset, limit)
      end

      def resolve_path(file_path)
        File.absolute_path?(file_path) ? file_path : File.join(root_path, file_path)
      end

      def list_directory(full_path, file_path)
        entries = Dir.entries(full_path).reject { |e| e.start_with?(".") }.sort
        "Directory listing for '#{file_path}':\n" + entries.map { |e| "  #{e}" }.join("\n")
      end

      def format_file_lines(full_path, offset, limit)
        lines = File.readlines(full_path)
        start_idx = [offset - 1, 0].max
        end_idx = [start_idx + limit - 1, lines.length - 1].min

        formatted_lines = (start_idx..end_idx).map do |i|
          format_line(lines[i], i + 1)
        end.join("\n")

        ToolResult.new(
          content: formatted_lines,
          metadata: { line_count: end_idx - start_idx + 1, truncated: end_idx < lines.length - 1 }
        )
      end

      def format_line(line, line_num)
        content = line.chomp
        content = "#{content[0..2000]}..." if content.length > 2000
        "#{line_num}: #{content}"
      end
    end
  end
end
