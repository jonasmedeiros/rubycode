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

        validate_file_does_not_exist(file_path, full_path)
        request_approval(file_path, content)
        create_file(full_path, content)
        build_result(file_path, content)
      end

      def validate_file_does_not_exist(file_path, full_path)
        return unless File.exist?(full_path)

        raise ToolError, I18n.t("rubycode.errors.file_exists", path: file_path)
      end

      def request_approval(file_path, content)
        approval_handler = context[:approval_handler]
        return if approval_handler.request_write_approval(file_path, content)

        raise ToolError, I18n.t("rubycode.errors.user_cancelled_write")
      end

      def create_file(full_path, content)
        dir = File.dirname(full_path)
        FileUtils.mkdir_p(dir)
        File.write(full_path, content)
      end

      def build_result(file_path, content)
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
