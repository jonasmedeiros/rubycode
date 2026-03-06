# frozen_string_literal: true

require "net/http"
require "uri"
require "json"

module RubyCode
  module SearchProviders
    # DuckDuckGo Instant Answer API provider (FREE)
    # https://duckduckgo.com/api
    # Note: Returns instant answers/summaries, not full web search results
    class DuckduckgoInstant
      API_ENDPOINT = "https://api.duckduckgo.com/"

      def search(query, max_results: 5)
        uri = build_uri(query)
        response = make_request(uri)

        parse_results(response.body, max_results)
      end

      private

      def build_uri(query)
        URI(API_ENDPOINT).tap do |uri|
          uri.query = URI.encode_www_form(
            q: query,
            format: "json",
            no_html: 1,
            skip_disambig: 1
          )
        end
      end

      def make_request(uri)
        Net::HTTP.start(uri.host, uri.port, use_ssl: true,
                        read_timeout: 10, open_timeout: 10) do |http|
          request = Net::HTTP::Get.new(uri)
          request["User-Agent"] = "RubyCode/#{RubyCode::VERSION}"
          http.request(request)
        end
      end

      def parse_results(json_body, max_results)
        data = JSON.parse(json_body)
        results = []

        # Add main abstract if available
        if data["Abstract"] && !data["Abstract"].empty?
          results << {
            title: data["Heading"] || "Summary",
            url: data["AbstractURL"] || "",
            snippet: data["Abstract"]
          }
        end

        # Add related topics
        related = data["RelatedTopics"] || []
        related.first(max_results - results.length).each do |topic|
          # Skip if it's a category (has Topics key)
          next if topic["Topics"]

          results << {
            title: topic["Text"]&.split(" - ")&.first || "Related",
            url: topic["FirstURL"] || "",
            snippet: topic["Text"] || ""
          }
        end

        # Add results from other sources
        if results.empty? && data["Results"]
          data["Results"].first(max_results).each do |result|
            results << {
              title: result["Text"] || "Result",
              url: result["FirstURL"] || "",
              snippet: result["Text"] || ""
            }
          end
        end

        results
      end
    end
  end
end
