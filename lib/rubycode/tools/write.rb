# frozen_string_literal: true

require "fileutils"

module RubyCode
  module Tools
    # Tool for creating new files
    class Write < Base
      private

      def perform(params)
        file_path = params["file_path"]
        content = params["content"]
        full_path = resolve_path(file_path)

        # Error if file exists
        if File.exist?(full_path)
          raise ToolError,
                "File '#{file_path}' already exists. Use 'update' tool to modify it."
        end

        # Request user approval
        approval_handler = context[:approval_handler]
        unless approval_handler.request_write_approval(file_path, content)
          raise ToolError,
                "USER CANCELLED: The user declined to create this file. Do not retry this operation. Ask the user if they want to make a different change or call 'done' to finish."
        end

        # Create directory if needed
        dir = File.dirname(full_path)
        FileUtils.mkdir_p(dir)

        # Write file
        File.write(full_path, content)

        ToolResult.new(
          content: "Created '#{file_path}' (#{content.lines.count} lines)",
          metadata: {
            file_path: file_path,
            lines: content.lines.count,
            bytes: content.bytesize
          }
        )
      end

      def resolve_path(file_path)
        File.absolute_path?(file_path) ? file_path : File.join(root_path, file_path)
      end
    end
  end
end
