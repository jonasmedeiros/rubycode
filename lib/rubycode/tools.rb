# frozen_string_literal: true

require_relative "tools/base"
require_relative "tools/bash"
require_relative "tools/read"
require_relative "tools/search"
require_relative "tools/write"
require_relative "tools/update"
require_relative "tools/done"
require_relative "tools/web_search"
require_relative "tools/fetch"
require_relative "tools/explore"

module RubyCode
  # Collection of available tools for the AI agent
  module Tools
    # Registry of all available tools
    TOOLS = [
      Bash,
      Read,
      Search,
      Write,
      Update,
      Done,
      WebSearch,
      Fetch,
      Explore
    ].freeze

    def self.definitions
      TOOLS.map(&:definition)
    end

    def self.execute(tool_name:, params:, context:)
      tool_class = TOOLS.find { |t| t.definition[:function][:name] == tool_name }

      raise ToolError, "Unknown tool '#{tool_name}'" unless tool_class

      # Instantiate tool and call execute
      tool_instance = tool_class.new(context: context)
      result = tool_instance.execute(params)

      # Convert result to string for history compatibility
      result.respond_to?(:to_s) ? result.to_s : result
    end
  end
end
