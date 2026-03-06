# frozen_string_literal: true

require "net/http"
require "uri"
require "json"

module RubyCode
  module SearchProviders
    # Brave Search API provider
    # https://brave.com/search/api/
    class BraveSearch
      API_ENDPOINT = "https://api.search.brave.com/res/v1/web/search"

      def initialize(api_key:)
        @api_key = api_key
      end

      def search(query, max_results: 5)
        uri = build_uri(query, max_results)
        response = make_request(uri)

        parse_results(response.body)
      end

      private

      def build_uri(query, max_results)
        URI(API_ENDPOINT).tap do |uri|
          uri.query = URI.encode_www_form(
            q: query,
            count: max_results
          )
        end
      end

      def make_request(uri)
        Net::HTTP.start(uri.host, uri.port, use_ssl: true,
                                            read_timeout: 10, open_timeout: 10) do |http|
          request = Net::HTTP::Get.new(uri)
          request["Accept"] = "application/json"
          request["X-Subscription-Token"] = @api_key
          http.request(request)
        end
      end

      def parse_results(json_body)
        data = JSON.parse(json_body)
        results = data.dig("web", "results") || []

        results.map do |result|
          {
            title: result["title"],
            url: result["url"],
            snippet: result["description"] || ""
          }
        end
      end
    end
  end
end
