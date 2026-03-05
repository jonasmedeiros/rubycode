# frozen_string_literal: true

require "pastel"

module RubyCode
  class Client
    # Handles user approval prompts for tools
    class ApprovalHandler
      def initialize(tty_prompt:, config:)
        @prompt = tty_prompt
        @config = config
        @pastel = Pastel.new
      end

      def request_bash_approval(command, base_command, safe_commands)
        puts "\n#{@pastel.red("━" * 80)}"
        puts @pastel.bold.red("⚠ WARNING: Non-Whitelisted Command")
        puts "#{@pastel.cyan("Command:")} #{command}"
        puts "#{@pastel.cyan("Base command:")} #{base_command}"
        puts @pastel.red("─" * 80)
        puts @pastel.yellow("This command is not in the safe whitelist:")
        puts @pastel.dim("Safe commands: #{safe_commands.join(", ")}")
        puts ""
        puts @pastel.yellow("⚠ Only approve if you trust this command will not cause harm")
        puts @pastel.red("━" * 80)

        approved = request_approval("Execute this command?")

        puts @pastel.yellow("   ⓘ Skipped: User declined to execute '#{base_command}'") unless approved

        approved
      end

      def request_write_approval(file_path, content)
        puts "\n#{@pastel.yellow("━" * 80)}"
        puts @pastel.bold("Write Operation - Approval Required")
        puts "#{@pastel.cyan("File:")} #{file_path}"
        puts "#{@pastel.cyan("Lines:")} #{content.lines.count}"
        puts @pastel.yellow("─" * 80)

        # Show preview (first 20 lines or all if less)
        preview_lines = content.lines.first(20)
        puts preview_lines.join
        puts @pastel.dim("... (#{content.lines.count - 20} more lines)") if content.lines.count > 20

        puts @pastel.yellow("━" * 80)

        approved = request_approval("Create this file?")

        puts @pastel.yellow("   ⓘ Skipped: User declined to create #{file_path}") unless approved

        approved
      end

      def request_update_approval(file_path, old_string, new_string)
        puts "\n#{@pastel.yellow("━" * 80)}"
        puts @pastel.bold("Update Operation - Approval Required")
        puts "#{@pastel.cyan("File:")} #{file_path}"
        puts @pastel.yellow("─" * 80)

        # Show old content
        puts @pastel.red("- REMOVE:")
        old_string.lines.each { |line| puts @pastel.red("  - #{line.chomp}") }

        puts ""

        # Show new content
        puts @pastel.green("+ ADD:")
        new_string.lines.each { |line| puts @pastel.green("  + #{line.chomp}") }

        puts @pastel.yellow("━" * 80)

        approved = request_approval("Apply this update?")

        puts @pastel.yellow("   ⓘ Skipped: User declined to update #{file_path}") unless approved

        approved
      end

      private

      def request_approval(question)
        prompt = @prompt || TTY::Prompt.new(input: $stdin, output: $stdout)
        prompt.yes?(question) do |q|
          q.default false
        end
      end
    end
  end
end
