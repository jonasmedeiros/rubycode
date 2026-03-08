# frozen_string_literal: true

require "net/http"
require "uri"
require "json"
require_relative "base"

module RubyCode
  module SearchProviders
    # DuckDuckGo Instant Answer API provider (FREE)
    # https://duckduckgo.com/api
    # Note: Returns instant answers/summaries, not full web search results
    class DuckduckgoInstant < Base
      API_ENDPOINT = "https://api.duckduckgo.com/"

      def initialize(config: nil)
        super(config: config, api_key: nil)
      end

      private

      def provider_name
        "DuckDuckGo"
      end

      def build_request(query, _max_results)
        URI(API_ENDPOINT).tap do |uri|
          uri.query = URI.encode_www_form(
            q: query,
            format: "json",
            no_html: 1,
            skip_disambig: 1
          )
        end
      end

      def parse_results(json_body, max_results)
        data = JSON.parse(json_body)
        results = []

        add_abstract_result(results, data)
        add_related_topics(results, data, max_results)
        add_other_results(results, data, max_results) if results.empty?

        results
      rescue JSON::ParserError => e
        raise SearchProviderError, "Failed to parse DuckDuckGo response: #{e.message}"
      end

      def add_abstract_result(results, data)
        return unless data["Abstract"] && !data["Abstract"].empty?

        results << {
          title: data["Heading"] || "Summary",
          url: data["AbstractURL"] || "",
          snippet: data["Abstract"]
        }
      end

      def add_related_topics(results, data, max_results)
        related = data["RelatedTopics"] || []
        related.first(max_results - results.length).each do |topic|
          next if skip_topic?(topic)

          results << build_topic_result(topic)
        end
      end

      def skip_topic?(topic)
        topic["Topics"] # Skip categories
      end

      def build_topic_result(topic)
        {
          title: extract_topic_title(topic),
          url: topic["FirstURL"] || "",
          snippet: topic["Text"] || ""
        }
      end

      def extract_topic_title(topic)
        topic["Text"]&.split(" - ")&.first || "Related"
      end

      def add_other_results(results, data, max_results)
        return unless data["Results"]

        data["Results"].first(max_results).each do |result|
          results << {
            title: result["Text"] || "Result",
            url: result["FirstURL"] || "",
            snippet: result["Text"] || ""
          }
        end
      end
    end
  end
end
