# frozen_string_literal: true

require "json"

module RubyCode
  module Tools
    class Base
      attr_reader :context

      def initialize(context:)
        @context = context
      end

      def execute(params)
        validate_params!(params)
        result = perform(params)
        wrap_result(result)
      rescue ToolError => e
        raise e
      rescue StandardError => e
        raise ToolError, "Error in #{self.class.name}: #{e.message}"
      end

      def self.definition
        @definition ||= load_schema
      end

      def self.load_schema
        tool_name = name.split("::").last.downcase
        schema_path = File.join(__dir__, "..", "..", "..", "config", "tools", "#{tool_name}.json")

        raise ToolError, "Schema file not found: #{schema_path}" unless File.exist?(schema_path)

        JSON.parse(File.read(schema_path), symbolize_names: true)
      end

      private

      def perform(params)
        raise NotImplementedError, "#{self.class.name} must implement #perform"
      end

      def validate_params!(params)
        return unless self.class.definition.dig(:function, :parameters, :required)

        required_params = self.class.definition.dig(:function, :parameters, :required)
        required_params.each do |param|
          next if params.key?(param) || params.key?(param.to_s)

          raise ToolError, "Missing required parameter: #{param}"
        end
      end

      def wrap_result(result)
        case result
        when ToolResult, CommandResult
          result
        when String
          ToolResult.new(content: result)
        else
          ToolResult.new(content: result.to_s)
        end
      end

      def root_path
        context[:root_path]
      end
    end
  end
end
