# frozen_string_literal: true

require "net/http"
require "uri"
require "json"
require_relative "base"

module RubyCode
  module SearchProviders
    # Exa.ai search provider - AI-native search engine optimized for LLMs
    # https://exa.ai
    # Uses MCP (Model Context Protocol) endpoint
    class ExaAi < Base
      MCP_ENDPOINT = "https://mcp.exa.ai/mcp"
      TIMEOUT = 25 # seconds

      def initialize(api_key: nil, config: nil)
        super(config: config, api_key: api_key || ENV.fetch("EXA_API_KEY", nil))
      end

      private

      def provider_name
        "Exa.ai"
      end

      def requires_api_key?
        true
      end

      def build_request(query, max_results)
        uri = URI(MCP_ENDPOINT)
        request = Net::HTTP::Post.new(uri)
        request["Content-Type"] = "application/json"
        request["Accept"] = "application/json, text/event-stream"
        request["User-Agent"] = "RubyCode/#{RubyCode::VERSION}"

        request.body = build_mcp_payload(query, max_results).to_json

        { uri: uri, request: request }
      end

      def build_mcp_payload(query, max_results)
        {
          jsonrpc: "2.0",
          id: 1,
          method: "tools/call",
          params: {
            name: "web_search_exa",
            arguments: {
              query: query,
              type: "auto",
              numResults: max_results,
              livecrawl: "fallback",
              contextMaxCharacters: 10_000
            }
          }
        }
      end

      def parse_results(body, _max_results)
        results = []

        # Parse SSE (Server-Sent Events) response
        body.split("\n").each do |line|
          next unless line.start_with?("data: ")

          process_sse_line(line, results)
        end

        results
      rescue JSON::ParserError => e
        raise SearchProviderError, "Failed to parse Exa.ai response: #{e.message}"
      end

      def process_sse_line(line, results)
        data = JSON.parse(line[6..]) # Skip "data: " prefix
        return unless data["result"]&.dig("content")

        data["result"]["content"].each do |item|
          next unless item["type"] == "text"

          results.concat(parse_markdown_results(item["text"]))
        end
      end

      def parse_markdown_results(text)
        results = []
        current_result = {}
        collecting_text = false

        text.split("\n").each do |line|
          line = line.strip
          next if line.empty?

          result = process_markdown_line(line, current_result, results, collecting_text)
          collecting_text = result[:collecting]
        end

        finalize_result(current_result, results)
        cleanup_snippets(results)

        results
      end

      def process_markdown_line(line, current_result, results, collecting_text)
        return handle_title_line(line, current_result, results) if line.start_with?("Title:")
        return handle_url_line(line, current_result, collecting_text) if line.start_with?("URL:")
        return handle_text_line(line, current_result) if line.start_with?("Text:")

        handle_content_line(line, current_result, collecting_text)
      end

      def handle_title_line(line, current_result, results)
        save_current_result(current_result, results)
        start_new_result(line, current_result)
        { collecting: false }
      end

      def handle_url_line(line, current_result, collecting_text)
        current_result[:url] = line.sub("URL:", "").strip if current_result[:title]
        { collecting: collecting_text }
      end

      def handle_text_line(line, current_result)
        current_result[:snippet] = line.sub("Text:", "").strip if current_result[:title]
        { collecting: true }
      end

      def handle_content_line(line, current_result, collecting_text)
        return { collecting: collecting_text } unless collecting_text && current_result[:title]

        append_text_if_valid(line, current_result)
        { collecting: collecting_text }
      end

      def save_current_result(current_result, results)
        return unless current_result[:title] && current_result[:url] && !current_result[:url].empty?

        results << current_result
      end

      def start_new_result(line, current_result)
        current_result.replace(
          title: line.sub("Title:", "").strip,
          url: "",
          snippet: ""
        )
      end

      def append_text_if_valid(line, current_result)
        return if current_result[:snippet].length >= 500

        break_keywords = ["Title:", "Author:", "Published Date:", "URL:"]
        return if break_keywords.any? { |kw| line.start_with?(kw) }

        current_result[:snippet] = "#{current_result[:snippet]} #{line}"
      end

      def finalize_result(current_result, results)
        save_current_result(current_result, results)
      end

      def cleanup_snippets(results)
        results.each do |result|
          result[:snippet] = result[:snippet].strip[0..300] # Limit to 300 chars
        end
      end
    end
  end
end
