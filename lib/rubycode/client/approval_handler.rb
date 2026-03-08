# frozen_string_literal: true

module RubyCode
  class Client
    # Handles user approval prompts for tools
    class ApprovalHandler
      attr_reader :auto_approve_write_enabled

      def initialize(tty_prompt:, config:)
        @prompt = tty_prompt
        @config = config
        @auto_approve_write_enabled = false
      end

      def enable_auto_approve_write
        @auto_approve_write_enabled = true
      end

      def disable_auto_approve_write
        @auto_approve_write_enabled = false
      end

      def request_bash_approval(command, base_command, safe_commands)
        display = Views::BashApproval.build(
          command: command,
          base_command: base_command,
          safe_commands: safe_commands
        )
        puts display

        approved = request_approval("Execute this command?")

        puts Views::SkipNotification.build(message: "User declined to execute '#{base_command}'") unless approved

        approved
      end

      def request_write_approval(file_path, content)
        return true if @auto_approve_write_enabled

        display = Views::WriteApproval.build(
          file_path: file_path,
          content: content
        )
        puts display

        approved = request_approval("Create this file?")

        puts Views::SkipNotification.build(message: "User declined to create #{file_path}") unless approved

        approved
      end

      def request_update_approval(file_path, old_string, new_string)
        return true if @auto_approve_write_enabled

        display = Views::UpdateApproval.build(
          file_path: file_path,
          old_string: old_string,
          new_string: new_string
        )
        puts display

        approved = request_approval("Apply this update?")

        puts Views::SkipNotification.build(message: "User declined to update #{file_path}") unless approved

        approved
      end

      def request_web_search_approval(query, max_results)
        display = Views::WebSearchApproval.build(
          query: query,
          max_results: max_results
        )
        puts display

        approved = request_approval("Perform this web search?")

        puts Views::SkipNotification.build(message: "User declined web search for '#{query}'") unless approved

        approved
      end

      private

      def request_approval(question)
        # Flush output to ensure prompt is visible
        $stdout.flush

        # Always create a fresh prompt instance to ensure stdin is available
        prompt = TTY::Prompt.new(input: $stdin, output: $stdout, interrupt: :exit)
        prompt.yes?(question) do |q|
          q.default false
        end
      end
    end
  end
end
