# frozen_string_literal: true

require "net/http"
require "uri"
require "json"
require_relative "base"

module RubyCode
  module SearchProviders
    # Brave Search API provider
    # https://brave.com/search/api/
    class BraveSearch < Base
      API_ENDPOINT = "https://api.search.brave.com/res/v1/web/search"

      def initialize(api_key: nil, config: nil)
        super(config: config, api_key: api_key)
      end

      private

      def provider_name
        "BraveSearch"
      end

      def requires_api_key?
        true
      end

      def build_request(query, max_results)
        uri = URI(API_ENDPOINT).tap do |u|
          u.query = URI.encode_www_form(
            q: query,
            count: max_results
          )
        end

        request = Net::HTTP::Get.new(uri)
        request["Accept"] = "application/json"
        request["X-Subscription-Token"] = api_key

        { uri: uri, request: request }
      end

      def parse_results(json_body, _max_results)
        data = JSON.parse(json_body)
        results = data.dig("web", "results") || []

        results.map do |result|
          {
            title: result["title"],
            url: result["url"],
            snippet: result["description"] || ""
          }
        end
      rescue JSON::ParserError => e
        raise SearchProviderError, "Failed to parse Brave Search response: #{e.message}"
      end
    end
  end
end
