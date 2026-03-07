# frozen_string_literal: true

require_relative "concerns/http_client"
require_relative "concerns/error_handling"
require_relative "concerns/debugging"

module RubyCode
  module SearchProviders
    # Base class for search providers
    class Base
      include Concerns::HttpClient
      include Concerns::ErrorHandling
      include Concerns::Debugging

      def initialize(config: nil, api_key: nil)
        @config = config
        @api_key = api_key
        validate_api_key! if requires_api_key?
      end

      def search(query, max_results: 5)
        uri_or_request = build_request(query, max_results)

        debug_search_request(query, max_results, uri_or_request) if debug_enabled?

        response = make_http_request(uri_or_request)

        debug_search_response(response) if debug_enabled?

        parse_results(response.body, max_results)
      end

      private

      # Abstract methods to be implemented by subclasses
      def provider_name
        raise NotImplementedError, "Subclass must define provider_name"
      end

      def build_request(_query, _max_results)
        raise NotImplementedError, "Subclass must define build_request"
      end

      def parse_results(_body, _max_results)
        raise NotImplementedError, "Subclass must define parse_results"
      end

      # Concrete shared methods
      def requires_api_key?
        # Override in subclass if API key is required
        false
      end

      attr_reader :api_key

      def validate_api_key!
        return if api_key && !api_key.empty?

        raise SearchProviderError, I18n.t("rubycode.errors.search_provider.api_key_missing",
                                          provider: provider_name)
      end

      def debug_enabled?
        @config&.debug || false
      end
    end
  end
end
