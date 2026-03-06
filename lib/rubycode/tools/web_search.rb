# frozen_string_literal: true

require "ferrum"
require "nokogiri"
require_relative "../browser_manager"

module RubyCode
  module Tools
    # Tool for searching the web and verifying link existence
    class WebSearch < Base
      DUCKDUCKGO_URL = "https://html.duckduckgo.com/html/"
      HEAD_REQUEST_TIMEOUT = 5

      private

      def perform(params)
        query = params["query"]
        max_results = params["max_results"] || 5

        request_approval(query, max_results)
        results = search_duckduckgo(query, max_results)
        format_results(results)
      rescue StandardError => e
        raise ToolError, "Search failed: #{e.message}"
      end

      def request_approval(query, max_results)
        approval_handler = context[:approval_handler]
        return if approval_handler.request_web_search_approval(query, max_results)

        raise ToolError, I18n.t("rubycode.errors.user_cancelled_search")
      end

      def search_duckduckgo(query, max_results)
        html = fetch_search_results(query)
        results = parse_search_results(html)
        verified_results = verify_results(results, max_results)
        verified_results.first(max_results)
      end

      def fetch_search_results(query)
        browser = BrowserManager.browser
        browser.go_to(DUCKDUCKGO_URL)
        browser.network.wait_for_idle

        # Fill search form and submit
        browser.at_css('input[name="q"]').focus.type(query)
        browser.at_css('input[type="submit"]').click

        # Wait for results page to load
        browser.network.wait_for_idle(timeout: 10)

        # Get rendered HTML and force UTF-8 encoding
        html = browser.body
        html.force_encoding("UTF-8")
      rescue Ferrum::TimeoutError => e
        raise ToolError, "Search timed out: #{e.message}"
      rescue Ferrum::NetworkError, Ferrum::StatusError => e
        raise HTTPError, "Search request failed: #{e.message}"
      end

      def parse_search_results(html)
        doc = Nokogiri::HTML(html)
        results = []

        doc.css(".result").each do |result_div|
          result = extract_result_data(result_div)
          results << result if result
        end

        results
      end

      def extract_result_data(result_div)
        title_elem = result_div.at_css(".result__a")
        return nil unless title_elem

        snippet_elem = result_div.at_css(".result__snippet")
        title = title_elem.text.strip
        url = normalize_url(title_elem["href"])
        snippet = snippet_elem&.text&.strip || ""

        { title: title, url: url, snippet: snippet } if url
      end

      def normalize_url(url)
        return nil unless url

        # DuckDuckGo sometimes returns relative URLs, make them absolute
        url.start_with?("//") ? "https:#{url}" : url
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
        # Create a new page for verification (sequential approach)
        page = BrowserManager.browser.create_page
        page.go_to(url)

        # Check status code
        status = page.network.status
        page.close

        status >= 200 && status < 400
      rescue StandardError
        page&.close
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
