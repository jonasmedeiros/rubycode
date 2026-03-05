# frozen_string_literal: true

module RubyCode
  module Tools
    # Tool for updating existing files
    class Update < Base
      private

      def perform(params)
        file_path = params["file_path"]
        old_string = params["old_string"]
        new_string = params["new_string"]

        full_path = resolve_path(file_path)

        # Check file exists
        raise FileNotFoundError, "File '#{file_path}' not found" unless File.exist?(full_path)

        # Auto-read if not already read
        read_files = context[:read_files]
        unless read_files&.include?(full_path)
          display_formatter = context[:display_formatter]
          display_formatter.display_info("Auto-reading file before update...")
          # Mark as read
          read_files&.add(full_path)
        end

        # Read current content
        content = File.read(full_path)

        # Check if old_string exists
        unless content.include?(old_string)
          raise ToolError,
                "String not found in file. Searched for:\n#{old_string[0..100]}..."
        end

        # Check if replacement is unique
        occurrences = content.scan(old_string).count
        if occurrences > 1
          raise ToolError,
                "String appears #{occurrences} times. Must be unique for safe replacement."
        end

        # Request user approval
        approval_handler = context[:approval_handler]
        unless approval_handler.request_update_approval(file_path, old_string, new_string)
          raise ToolError,
                "USER CANCELLED: The user declined this change. Do not retry this exact update. Either move to the next change or call 'done' to finish."
        end

        # Perform replacement
        new_content = content.sub(old_string, new_string)

        # Write back
        File.write(full_path, new_content)

        ToolResult.new(
          content: "Updated '#{file_path}' (replaced #{old_string.lines.count} lines)",
          metadata: {
            file_path: file_path,
            old_lines: old_string.lines.count,
            new_lines: new_string.lines.count
          }
        )
      end

      def resolve_path(file_path)
        File.absolute_path?(file_path) ? file_path : File.join(root_path, file_path)
      end
    end
  end
end
