# frozen_string_literal: true

module Rubycode
  module Tools
    # Tool for signaling task completion
    class Done
      SCHEMA = {
        type: "function",
        function: {
          name: "done",
          description: "Call this when you have found the code and are ready to provide your " \
                       "final answer. This signals you are finished exploring.",
          parameters: {
            type: "object",
            properties: {
              answer: {
                type: "string",
                description: "Your final answer showing the file, line number, current code, and suggested change"
              }
            },
            required: ["answer"]
          }
        }
      }.freeze

      def self.definition
        SCHEMA
      end

      def self.execute(params:, _context: nil)
        params["answer"]
      end
    end
  end
end
