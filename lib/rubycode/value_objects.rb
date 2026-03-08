# frozen_string_literal: true

module RubyCode
  # Represents a conversation message
  class Message
    attr_reader :role, :content, :timestamp, :tool_calls

    def initialize(role:, content:, tool_calls: nil)
      @role = role
      @content = content
      @tool_calls = tool_calls
      @timestamp = Time.now
    end

    def to_h
      hash = { role: role, content: content }
      hash[:tool_calls] = tool_calls if tool_calls && !tool_calls.empty?
      hash
    end

    def ==(other)
      other.is_a?(Message) &&
        role == other.role &&
        content == other.content &&
        tool_calls == other.tool_calls
    end
  end

  # Represents a tool call from the LLM
  class ToolCall
    attr_reader :name, :arguments

    def initialize(name:, arguments:)
      @name = name
      @arguments = arguments
    end

    def to_h
      { name: name, arguments: arguments }
    end

    def ==(other)
      other.is_a?(ToolCall) &&
        name == other.name &&
        arguments == other.arguments
    end
  end

  # Represents the result of a tool execution
  class ToolResult
    attr_reader :content, :metadata

    def initialize(content:, metadata: {})
      @content = content
      @metadata = metadata
    end

    def to_s
      content
    end

    def truncated?
      metadata[:truncated] == true
    end

    def line_count
      metadata[:line_count]
    end

    def ==(other)
      other.is_a?(ToolResult) &&
        content == other.content &&
        metadata == other.metadata
    end
  end

  # Represents the result of a bash command execution
  class CommandResult
    attr_reader :stdout, :stderr, :exit_code

    def initialize(stdout:, stderr: "", exit_code: 0)
      @stdout = stdout
      @stderr = stderr
      @exit_code = exit_code
    end

    def success?
      exit_code.zero?
    end

    def output
      success? ? stdout : stderr
    end

    def to_s
      output
    end

    def ==(other)
      other.is_a?(CommandResult) &&
        stdout == other.stdout &&
        stderr == other.stderr &&
        exit_code == other.exit_code
    end
  end
end
