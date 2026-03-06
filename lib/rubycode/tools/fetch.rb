# frozen_string_literal: true

require "ferrum"
require "nokogiri"
require_relative "../browser_manager"

module RubyCode
  module Tools
    # Tool for fetching HTML content from URLs
    class Fetch < Base
      MAX_TEXT_SIZE = 50 * 1024 # 50KB limit for text extraction

      private

      def perform(params)
        url = params["url"]
        extract_text = params["extract_text"] || false

        validate_url!(url)

        html = fetch_url(url)
        output = extract_text ? extract_text_content(html) : html

        ToolResult.new(content: output)
      rescue URLError, HTTPError, NetworkError
        raise # Re-raise specific errors without wrapping
      rescue URI::InvalidURIError => e
        raise URLError, "Invalid URL: #{e.message}"
      rescue SocketError, Errno::ECONNREFUSED, Errno::ETIMEDOUT => e
        raise NetworkError, "Network error: #{e.message}"
      rescue StandardError => e
        raise ToolError, "Fetch failed: #{e.message}"
      end

      def validate_url!(url)
        uri = URI.parse(url)
        raise URLError, "URL must have http or https scheme" unless %w[http https].include?(uri.scheme)
        raise URLError, "URL must have a hostname" if uri.hostname.nil? || uri.hostname.empty?
      end

      def fetch_url(url)
        browser = BrowserManager.browser
        browser.go_to(url)
        browser.network.wait_for_idle(timeout: 30)

        # Get rendered HTML and force UTF-8 encoding
        html = browser.body
        html.force_encoding("UTF-8")
      rescue Ferrum::TimeoutError => e
        raise NetworkError, "Request timed out: #{e.message}"
      rescue Ferrum::StatusError => e
        status = e.response&.status || "unknown"
        raise HTTPError, "HTTP #{status}: #{e.message}"
      rescue Ferrum::NetworkError => e
        raise NetworkError, "Network error: #{e.message}"
      end

      def extract_text_content(html)
        doc = Nokogiri::HTML(html)

        # Remove unwanted elements
        doc.css("script, style, nav, footer").each(&:remove)

        # Extract text from body
        body = doc.at_css("body")
        return "" unless body

        text = body.text
                   .gsub(/\s+/, " ")           # Normalize whitespace
                   .gsub(/\n\s*\n+/, "\n\n")   # Normalize newlines
                   .strip

        # Limit size
        if text.bytesize > MAX_TEXT_SIZE
          text = text[0...MAX_TEXT_SIZE] + "\n[Content truncated at #{MAX_TEXT_SIZE} bytes]"
        end

        text
      end
    end
  end
end
