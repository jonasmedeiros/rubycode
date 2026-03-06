# frozen_string_literal: true

require "net/http"
require "uri"
require "nokogiri"

module RubyCode
  module Tools
    # Tool for fetching HTML content from URLs
    class Fetch < Base
      MAX_TEXT_SIZE = 50 * 1024 # 50KB limit for text extraction
      REQUEST_TIMEOUT = 30

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
        uri = URI.parse(url)

        Net::HTTP.start(uri.host, uri.port, use_ssl: uri.scheme == "https",
                                            read_timeout: REQUEST_TIMEOUT, open_timeout: 10) do |http|
          request = Net::HTTP::Get.new(uri)
          request["User-Agent"] = "RubyCode/#{RubyCode::VERSION}"
          response = http.request(request)

          case response
          when Net::HTTPSuccess
            # Force UTF-8 encoding
            html = response.body
            html.force_encoding("UTF-8")
          when Net::HTTPRedirection
            # Follow redirect
            location = response["location"]
            raise HTTPError, "Redirect loop detected" if location == url

            # Handle relative redirects
            redirect_uri = URI.parse(location)
            redirect_uri = uri + location unless redirect_uri.absolute?

            fetch_url(redirect_uri.to_s)
          else
            raise HTTPError, "HTTP #{response.code}: #{response.message}"
          end
        end
      rescue Net::OpenTimeout, Net::ReadTimeout => e
        raise NetworkError, "Request timed out: #{e.message}"
      rescue SocketError, Errno::ECONNREFUSED => e
        raise NetworkError, "Connection failed: #{e.message}"
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
