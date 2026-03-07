# frozen_string_literal: true

require "English"
require "shellwords"

module RubyCode
  module Tools
    # Tool for executing bash commands with safety checks and approval workflow
    class Bash < Base
      SAFE_COMMANDS = %w[
        ls
        pwd
        find
        tree
        cat
        head
        tail
        wc
        file
        which
        echo
        grep
        rg
      ].freeze

      private

      def perform(params)
        command = params["command"].strip
        base_command = command.split.first

        unless SAFE_COMMANDS.include?(base_command)
          approval_handler = context[:approval_handler]
          unless approval_handler.request_bash_approval(command, base_command, SAFE_COMMANDS)
            message = I18n.t("rubycode.errors.user_cancelled_bash",
                             command: base_command,
                             safe_commands: SAFE_COMMANDS.join(", "))
            raise ToolError, message
          end
        end

        execute_command(command)
      end

      def execute_command(command)
        Dir.chdir(root_path) do
          require "open3"

          output_lines = []
          exit_code = 0

          # Stream output in real-time, wait for command to finish naturally
          Open3.popen2e(command, stdin_data: "") do |stdin, stdout_err, wait_thr|
            stdin.close # Close stdin to prevent interactive prompts

            stdout_err.each_line do |line|
              print line # Show output in real-time
              output_lines << line
            end

            exit_code = wait_thr.value.exitstatus
          end

          output = output_lines.join

          raise CommandExecutionError, "Command failed with exit code #{exit_code}:\n#{output}" unless exit_code.zero?

          CommandResult.new(
            stdout: truncate_output(output),
            stderr: "",
            exit_code: exit_code
          )
        end
      end

      def truncate_output(output)
        lines = output.split("\n")
        return output if lines.length <= 200

        truncated_output = lines[0..199].join("\n")
        "#{truncated_output}\n\n... (#{lines.length - 200} more lines truncated)"
      end
    end
  end
end
