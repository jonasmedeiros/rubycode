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

  # Base class for all network-related errors
  class NetworkError < ToolError; end

  # Raised when HTTP request fails
  class HTTPError < NetworkError; end

  # Raised when URL is invalid
  class URLError < NetworkError; end

  # Base class for all adapter-related errors
  class AdapterError < Error; end

  # Raised when adapter request times out
  class AdapterTimeoutError < AdapterError; end

  # Raised when adapter cannot connect to server
  class AdapterConnectionError < AdapterError; end

  # Raised when all retry attempts are exhausted
  class AdapterRetryExhaustedError < AdapterError; end
end
