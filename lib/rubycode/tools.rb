# frozen_string_literal: true

require_relative "tools/bash"
require_relative "tools/read"
require_relative "tools/search"
require_relative "tools/done"

module Rubycode
  # Collection of available tools for the AI agent
  module Tools
    # Registry of all available tools
    TOOLS = [
      Bash,
      Read,
      Search,
      Done
    ].freeze

    def self.definitions
      TOOLS.map(&:definition)
    end

    def self.execute(tool_name:, params:, context:)
      tool_class = TOOLS.find { |t| t.definition[:function][:name] == tool_name }

      return "Error: Unknown tool '#{tool_name}'" unless tool_class

      tool_class.execute(params: params, context: context)
    end
  end
end
