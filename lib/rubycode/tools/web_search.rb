# frozen_string_literal: true

require "net/http"
require "uri"
require_relative "../search_providers/multi_provider"
require_relative "../search_providers/exa_ai"
require_relative "../search_providers/duckduckgo_instant"
require_relative "../search_providers/brave_search"

module RubyCode
  module Tools
    # Tool for searching the web using multiple search providers
    class WebSearch < Base
      private

      def perform(params)
        query = params["query"]
        max_results = params["max_results"] || 5

        request_approval(query, max_results)
        results = search_web(query, max_results)
        format_results(results)
      rescue StandardError => e
        raise ToolError, "Search failed: #{e.message}"
      end

      def request_approval(query, max_results)
        approval_handler = context[:approval_handler]
        return if approval_handler.request_web_search_approval(query, max_results)

        raise ToolError, I18n.t("rubycode.errors.user_cancelled_search")
      end

      def search_web(query, max_results)
        results = fetch_and_parse_results(query, max_results)
        verified_results = verify_results(results, max_results)
        verified_results.first(max_results)
      end

      def fetch_and_parse_results(query, max_results)
        # Initialize multi-provider with fallback strategy
        multi = SearchProviders::MultiProvider.new

        # Primary: Exa.ai (AI-native search, PAID with free tier)
        exa_api_key = Models::ApiKey.get_key(adapter: :exa) || ENV["EXA_API_KEY"]
        if exa_api_key && !exa_api_key.empty?
          multi.add_provider(SearchProviders::ExaAi.new(api_key: exa_api_key))
        end

        # Fallback 1: DuckDuckGo Instant API (FREE)
        multi.add_provider(SearchProviders::DuckduckgoInstant.new)

        # Fallback 2: Brave Search API (PAID, if configured)
        brave_api_key = ENV["BRAVE_API_KEY"]
        if brave_api_key && !brave_api_key.empty?
          multi.add_provider(SearchProviders::BraveSearch.new(
                               api_key: brave_api_key
                             ))
        end

        # Search with automatic fallback
        multi.search(query, max_results: max_results * 2) # Get more to filter
      rescue StandardError => e
        raise ToolError, "All search providers failed: #{e.message}"
      end

      def verify_results(results, max_results)
        verified = []

        # Verify more than needed to account for dead links
        results.first(max_results * 2).each do |result|
          verified << result if url_exists?(result[:url])
          break if verified.size >= max_results
        end

        verified
      end

      def url_exists?(url)
        return false if url.nil? || url.empty?

        uri = URI.parse(url)

        Net::HTTP.start(uri.host, uri.port, use_ssl: uri.scheme == "https",
                                            read_timeout: 5, open_timeout: 5) do |http|
          request = Net::HTTP::Head.new(uri.request_uri)
          response = http.request(request)
          response.is_a?(Net::HTTPSuccess) || response.is_a?(Net::HTTPRedirection)
        end
      rescue StandardError
        false # Consider URL dead if verification fails
      end

      def format_results(results)
        return ToolResult.new(content: "No results found") if results.empty?

        formatted = results.map.with_index(1) do |result, idx|
          [
            "#{idx}. #{result[:title]}",
            "   URL: #{result[:url]}",
            "   #{result[:snippet]}",
            ""
          ].join("\n")
        end.join("\n")

        ToolResult.new(
          content: formatted.strip,
          metadata: {
            result_count: results.size,
            results: results
          }
        )
      end
    end
  end
end
