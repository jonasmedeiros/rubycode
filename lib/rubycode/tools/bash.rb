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
            safe_list = SAFE_COMMANDS.join(", ")
            message = "USER CANCELLED: The user declined to execute '#{base_command}'. " \
                      "Do not retry this command. Either use a whitelisted command (#{safe_list}) " \
                      "or call 'done' to finish."
            raise ToolError, message
          end
        end

        execute_command(command)
      end

      def execute_command(command)
        Dir.chdir(root_path) do
          output = `#{command} 2>&1`
          exit_code = $CHILD_STATUS.exitstatus

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
