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

          output, exit_code = run_command_with_streaming(command)
          raise CommandExecutionError, build_error_message(exit_code, output) unless exit_code.zero?

          build_command_result(output, exit_code)
        end
      end

      def run_command_with_streaming(command)
        output_lines = []
        exit_code = 0

        Open3.popen2e(command) do |stdin, stdout_err, wait_thr|
          stdin.close # Close stdin to prevent interactive prompts
          output_lines = stream_output(stdout_err)
          exit_code = wait_thr.value.exitstatus
        end

        [output_lines.join, exit_code]
      end

      def stream_output(stdout_err)
        output_lines = []
        stdout_err.each_line do |line|
          print line # Show output in real-time
          output_lines << line
        end
        output_lines
      end

      def build_error_message(exit_code, output)
        "Command failed with exit code #{exit_code}:\n#{output}"
      end

      def build_command_result(output, exit_code)
        CommandResult.new(
          stdout: truncate_output(output),
          stderr: "",
          exit_code: exit_code
        )
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
