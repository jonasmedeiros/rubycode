# frozen_string_literal: true

module RubyCode
  # Base error class for all RubyCode errors
  class Error < StandardError; end

  # Base class for all tool-related errors
  class ToolError < Error; end

  # Raised when attempting to execute an unsafe bash command
  class UnsafeCommandError < ToolError; end

  # Raised when a file is not found
  class FileNotFoundError < ToolError; end

  # Raised when a path is invalid or outside allowed directory
  class PathError < ToolError; end

  # Raised when command execution fails
  class CommandExecutionError < ToolError; end
end
