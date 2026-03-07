# frozen_string_literal: true

require "net/http"
require "uri"
require "json"

module RubyCode
  module SearchProviders
    # Exa.ai search provider - AI-native search engine optimized for LLMs
    # https://exa.ai
    # Uses MCP (Model Context Protocol) endpoint
    class ExaAi
      MCP_ENDPOINT = "https://mcp.exa.ai/mcp"
      DEFAULT_NUM_RESULTS = 8
      TIMEOUT = 25 # seconds

      def initialize(api_key: nil)
        @api_key = api_key || ENV["EXA_API_KEY"]
      end

      def search(query, max_results: 5, type: "auto", livecrawl: "fallback")
        return [] unless @api_key && !@api_key.empty?

        uri = URI(MCP_ENDPOINT)
        request = build_request(uri, query, max_results, type, livecrawl)
        response = make_request(uri, request)

        parse_results(response.body)
      rescue StandardError => e
        raise "Exa.ai search failed: #{e.message}"
      end

      private

      def build_request(uri, query, max_results, type, livecrawl)
        request = Net::HTTP::Post.new(uri)
        request["Content-Type"] = "application/json"
        request["Accept"] = "application/json, text/event-stream"
        request["User-Agent"] = "RubyCode/#{RubyCode::VERSION}"

        # Build MCP JSON-RPC 2.0 request
        request.body = {
          jsonrpc: "2.0",
          id: 1,
          method: "tools/call",
          params: {
            name: "web_search_exa",
            arguments: {
              query: query,
              type: type,
              numResults: max_results,
              livecrawl: livecrawl,
              contextMaxCharacters: 10_000
            }
          }
        }.to_json

        request
      end

      def make_request(uri, request)
        Net::HTTP.start(uri.host, uri.port, use_ssl: true,
                                            read_timeout: TIMEOUT,
                                            open_timeout: 10) do |http|
          http.request(request)
        end
      end

      def parse_results(body)
        results = []

        # Parse SSE (Server-Sent Events) response
        lines = body.split("\n")
        lines.each do |line|
          next unless line.start_with?("data: ")

          data = JSON.parse(line[6..]) # Skip "data: " prefix
          next unless data["result"] && data["result"]["content"]

          content_items = data["result"]["content"]
          content_items.each do |item|
            next unless item["type"] == "text"

            # Exa returns markdown formatted results with titles, URLs, and content
            text = item["text"]
            results.concat(parse_markdown_results(text))
          end
        end

        results
      rescue JSON::ParserError => e
        raise "Failed to parse Exa.ai response: #{e.message}"
      end

      def parse_markdown_results(text)
        # Exa returns results in format:
        # Title: ...
        # Author: ...
        # Published Date: ...
        # URL: ...
        # Text: ...
        results = []
        current_result = {}
        collecting_text = false

        text.split("\n").each do |line|
          line = line.strip
          next if line.empty?

          if line.start_with?("Title:")
            # Save previous result if exists and has URL
            if current_result[:title] && current_result[:url] && !current_result[:url].empty?
              results << current_result
            end

            current_result = {
              title: line.sub("Title:", "").strip,
              url: "",
              snippet: ""
            }
            collecting_text = false
          elsif line.start_with?("URL:") && current_result[:title]
            current_result[:url] = line.sub("URL:", "").strip
          elsif line.start_with?("Text:") && current_result[:title]
            # Start collecting text content
            current_result[:snippet] = line.sub("Text:", "").strip
            collecting_text = true
          elsif collecting_text && current_result[:title]
            # Stop collecting if we hit another metadata field or get too long
            break_keywords = ["Title:", "Author:", "Published Date:", "URL:"]
            if break_keywords.any? { |kw| line.start_with?(kw) }
              collecting_text = false
              redo # Process this line again
            end

            # Continue collecting text
            if current_result[:snippet].length < 500
              current_result[:snippet] += " " + line
            else
              collecting_text = false
            end
          end
        end

        # Add last result if valid
        if current_result[:title] && current_result[:url] && !current_result[:url].empty?
          results << current_result
        end

        # Clean up snippets
        results.each do |result|
          result[:snippet] = result[:snippet].strip[0..300] # Limit to 300 chars
        end

        results
      end
    end
  end
end
