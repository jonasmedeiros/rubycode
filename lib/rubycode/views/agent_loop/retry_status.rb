# frozen_string_literal: true

module RubyCode
  module Views
    module AgentLoop
      # Builds retry status message
      class RetryStatus
        def self.build(attempt:, max_retries:, delay:, error:)
          "⚠  Request failed: #{error}. Retrying in #{delay.round(1)}s... (attempt #{attempt}/#{max_retries})"
        end
      end
    end
  end
end
