# frozen_string_literal: true

require "net/http"
require "uri"
require "json"
require_relative "../searxng_instances"

module RubyCode
  module Tools
    # Tool for searching the web using SearXNG metasearch engine
    class WebSearch < Base
      REQUEST_TIMEOUT = 10
      MAX_INSTANCE_RETRIES = 3

      private

      def perform(params)
        query = params["query"]
        max_results = params["max_results"] || 5

        request_approval(query, max_results)
        results = search_searxng(query, max_results)
        format_results(results)
      rescue StandardError => e
        raise ToolError, "Search failed: #{e.message}"
      end

      def request_approval(query, max_results)
        approval_handler = context[:approval_handler]
        return if approval_handler.request_web_search_approval(query, max_results)

        raise ToolError, I18n.t("rubycode.errors.user_cancelled_search")
      end

      def search_searxng(query, max_results)
        results = fetch_and_parse_results(query)
        verified_results = verify_results(results, max_results)
        verified_results.first(max_results)
      end

      def fetch_and_parse_results(query)
        instance_tried = 0
        last_error = nil

        # Try multiple instances if one fails
        SearXNGInstances.all.shuffle.each do |instance|
          return fetch_from_instance(instance, query)
        rescue StandardError => e
          last_error = e
          instance_tried += 1
          next if instance_tried < MAX_INSTANCE_RETRIES
        end

        raise ToolError, "All SearXNG instances failed. Last error: #{last_error&.message}"
      end

      def fetch_from_instance(instance, query)
        uri = build_search_uri(instance, query)
        response = make_http_request(uri)

        unless response.is_a?(Net::HTTPSuccess)
          raise HTTPError, "HTTP #{response.code}: #{response.message}"
        end

        parse_json_results(response.body)
      end

      def build_search_uri(instance, query)
        URI("#{instance}/search").tap do |uri|
          uri.query = URI.encode_www_form(
            q: query,
            format: "json",
            language: "en"
          )
        end
      end

      def make_http_request(uri)
        Net::HTTP.start(uri.host, uri.port, use_ssl: uri.scheme == "https",
                        read_timeout: REQUEST_TIMEOUT, open_timeout: REQUEST_TIMEOUT) do |http|
          request = Net::HTTP::Get.new(uri)
          request["User-Agent"] = "RubyCode/#{RubyCode::VERSION}"
          http.request(request)
        end
      rescue Net::OpenTimeout, Net::ReadTimeout => e
        raise NetworkError, "Request timed out: #{e.message}"
      rescue SocketError, Errno::ECONNREFUSED => e
        raise NetworkError, "Connection failed: #{e.message}"
      end

      def parse_json_results(json_body)
        data = JSON.parse(json_body)
        results = data["results"] || []

        results.map do |result|
          {
            title: result["title"],
            url: result["url"],
            snippet: result["content"] || result["snippet"] || ""
          }
        end
      rescue JSON::ParserError => e
        raise ToolError, "Failed to parse search results: #{e.message}"
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
