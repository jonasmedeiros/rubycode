# frozen_string_literal: true

module RubyCode
  module Tools
    # Tool for signaling task completion
    class Done < Base
      private

      def perform(params)
        params["answer"]
      end
    end
  end
end
