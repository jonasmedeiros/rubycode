# frozen_string_literal: true

module Rubycode
  module Tools
    # Tool for signaling task completion
    class Done
      def self.definition
        {
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
        }
      end

      def self.execute(params:, context: nil)
        # Just return the answer - this is the final response
        params["answer"]
      end
    end
  end
end
