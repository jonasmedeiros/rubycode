# frozen_string_literal: true

module Rubycode
  module Adapters
    class Base
      def initialize(config)
        @config = config
      end

      def generate(prompt:)
        raise NotImplementedError
      end
    end
  end
end
