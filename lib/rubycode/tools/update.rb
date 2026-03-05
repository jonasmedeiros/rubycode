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
        validate_file_exists(file_path, full_path)
        auto_read_file_if_needed(full_path)

        content = File.read(full_path)
        validate_string_match(content, old_string)
        validate_uniqueness(content, old_string)
        request_approval(file_path, old_string, new_string)

        update_file(full_path, content, old_string, new_string)
        build_result(file_path, old_string, new_string)
      end

      def validate_file_exists(file_path, full_path)
        raise FileNotFoundError, "File '#{file_path}' not found" unless File.exist?(full_path)
      end

      def auto_read_file_if_needed(full_path)
        read_files = context[:read_files]
        return if read_files&.include?(full_path)

        context[:display_formatter].display_info("Auto-reading file before update...")
        read_files&.add(full_path)
      end

      def validate_string_match(content, old_string)
        return if content.include?(old_string)

        raise ToolError, "String not found in file. Searched for:\n#{old_string[0..100]}..."
      end

      def validate_uniqueness(content, old_string)
        occurrences = content.scan(old_string).count
        return if occurrences == 1

        raise ToolError, "String appears #{occurrences} times. Must be unique for safe replacement."
      end

      def request_approval(file_path, old_string, new_string)
        approval_handler = context[:approval_handler]
        return if approval_handler.request_update_approval(file_path, old_string, new_string)

        message = "USER CANCELLED: The user declined this change. Do not retry this exact update. " \
                  "Either move to the next change or call 'done' to finish."
        raise ToolError, message
      end

      def update_file(full_path, content, old_string, new_string)
        new_content = content.sub(old_string, new_string)
        File.write(full_path, new_content)
      end

      def build_result(file_path, old_string, new_string)
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
