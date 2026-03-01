# frozen_string_literal: true

module Rubycode
  module Tools
    class Read
      def self.definition
        {
          type: "function",
          function: {
            name: "read",
            description: "Read a file or directory from the filesystem.\n\n- Use this when you know the file path and want to see its contents\n- Returns file contents with line numbers (format: 'line_number: content')\n- For directories, returns a listing of entries\n- Use the search tool to find specific content in files\n- Use bash with 'ls' or 'find' to discover what files exist",
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
        }
      end

      def self.execute(params:, context:)
        file_path = params["file_path"]
        offset = params["offset"] || 1
        limit = params["limit"] || 2000

        # Resolve relative paths
        full_path = if File.absolute_path?(file_path)
                      file_path
                    else
                      File.join(context[:root_path], file_path)
                    end

        unless File.exist?(full_path)
          return "Error: File '#{file_path}' does not exist"
        end

        if File.directory?(full_path)
          # List directory contents instead
          entries = Dir.entries(full_path).reject { |e| e.start_with?(".") }.sort
          return "Directory listing for '#{file_path}':\n" + entries.map { |e| "  #{e}" }.join("\n")
        end

        lines = File.readlines(full_path)
        start_idx = [offset - 1, 0].max
        end_idx = [start_idx + limit - 1, lines.length - 1].min

        result = []
        (start_idx..end_idx).each do |i|
          line_num = i + 1
          content = lines[i].chomp
          # Truncate long lines
          content = content[0..2000] + "..." if content.length > 2000
          result << "#{line_num}: #{content}"
        end

        result.join("\n")
      rescue => e
        "Error reading file: #{e.message}"
      end
    end
  end
end
