# frozen_string_literal: true

require "tty-prompt"
require "pastel"
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
        unless request_approval(file_path, content)
          raise ToolError, "USER CANCELLED: The user declined to create this file. Do not retry this operation. Ask the user if they want to make a different change or call 'done' to finish."
        end

        # Create directory if needed
        dir = File.dirname(full_path)
        FileUtils.mkdir_p(dir) unless Dir.exist?(dir)

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

      def request_approval(file_path, content)
        pastel = Pastel.new
        prompt = context[:tty_prompt] || TTY::Prompt.new(input: $stdin, output: $stdout)

        # Show what will be written
        puts "\n#{pastel.yellow("━" * 80)}"
        puts pastel.bold("Write Operation - Approval Required")
        puts "#{pastel.cyan("File:")} #{file_path}"
        puts "#{pastel.cyan("Lines:")} #{content.lines.count}"
        puts pastel.yellow("─" * 80)

        # Show preview (first 20 lines or all if less)
        preview_lines = content.lines.first(20)
        puts preview_lines.join
        puts pastel.dim("... (#{content.lines.count - 20} more lines)") if content.lines.count > 20

        puts pastel.yellow("━" * 80)

        # Ask for approval
        approved = prompt.yes?("Create this file?") do |q|
          q.default false
        end

        unless approved
          puts pastel.yellow("   ⓘ Skipped: User declined to create #{file_path}")
        end

        approved
      end

      def resolve_path(file_path)
        File.absolute_path?(file_path) ? file_path : File.join(root_path, file_path)
      end
    end
  end
end
