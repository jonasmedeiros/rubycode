# frozen_string_literal: true

module RubyCode
  module Adapters
    module Concerns
      # Debug output for adapter requests and responses
      module Debugging
        private

        def debug_request(uri, payload)
          puts Views::Adapter::DebugRequest.build(
            adapter_name: adapter_name,
            url: sanitize_url(uri),
            model: @config.model,
            payload: payload
          )
        end

        def debug_response(body)
          puts Views::Adapter::DebugResponse.build(
            adapter_name: adapter_name,
            body: body
          )
        end

        def sanitize_url(uri)
          uri.to_s
        end
      end
    end
  end
end
