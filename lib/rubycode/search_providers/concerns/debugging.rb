# frozen_string_literal: true

module RubyCode
  module SearchProviders
    module Concerns
      # Debug output for search providers
      module Debugging
        private

        def debug_search_request(query, max_results, uri_or_request)
          url = if uri_or_request.is_a?(URI)
                  uri_or_request.to_s
                elsif uri_or_request.is_a?(Hash)
                  uri_or_request[:uri].to_s
                else
                  "Unknown"
                end

          puts Views::SearchProvider::DebugRequest.build(
            provider_name: provider_name,
            query: query,
            max_results: max_results,
            url: url
          )
        end

        def debug_search_response(response)
          puts Views::SearchProvider::DebugResponse.build(
            provider_name: provider_name,
            status_code: response.code,
            body_preview: response.body[0...500] # First 500 chars
          )
        end
      end
    end
  end
end
