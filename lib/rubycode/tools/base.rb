# frozen_string_literal: true

module RubyCode
  module Tools
    # Base class for all tools providing common functionality
    class Base
      attr_reader :context

      def initialize(context:)
        @context = context
      end

      # Public execute method that validates and calls perform
      def execute(params)
        validate_params!(params)
        result = perform(params)
        wrap_result(result)
      rescue ToolError => e
        # Re-raise tool errors as-is
        raise e
      rescue StandardError => e
        # Wrap unexpected errors in ToolError
        raise ToolError, "Error in #{self.class.name}: #{e.message}"
      end

      # Must be implemented by subclasses to define tool schema
      def self.definition
        raise NotImplementedError, "#{name} must implement self.definition"
      end

      private

      # Must be implemented by subclasses to perform the actual work
      def perform(params)
        raise NotImplementedError, "#{self.class.name} must implement #perform"
      end

      # Validates required parameters based on schema
      def validate_params!(params)
        return unless self.class.definition.dig(:function, :parameters, :required)

        required_params = self.class.definition.dig(:function, :parameters, :required)
        required_params.each do |param|
          next if params.key?(param) || params.key?(param.to_s)

          raise ToolError, "Missing required parameter: #{param}"
        end
      end

      # Wraps string results in ToolResult, passes through ToolResult and CommandResult
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

      # Helper to get root path from context
      def root_path
        context[:root_path]
      end
    end
  end
end
