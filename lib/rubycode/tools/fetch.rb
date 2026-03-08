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

        build_tool_result(url, output, extract_text)
      rescue URLError, HTTPError, NetworkError
        raise # Re-raise specific errors without wrapping
      rescue URI::InvalidURIError => e
        raise URLError, "Invalid URL: #{e.message}"
      rescue SocketError, Errno::ECONNREFUSED, Errno::ETIMEDOUT => e
        raise NetworkError, "Network error: #{e.message}"
      rescue StandardError => e
        raise ToolError, "Fetch failed: #{e.message}"
      end

      def build_tool_result(url, output, extract_text)
        ToolResult.new(
          content: output,
          metadata: {
            url: url,
            size_bytes: output.bytesize,
            extract_text: extract_text
          }
        )
      end

      def validate_url!(url)
        uri = URI.parse(url)
        raise URLError, "URL must have http or https scheme" unless %w[http https].include?(uri.scheme)
        raise URLError, "URL must have a hostname" if uri.hostname.nil? || uri.hostname.empty?
      end

      def fetch_url(url)
        uri = URI.parse(url)
        response = make_http_request(uri)
        handle_response(response, uri, url)
      rescue Net::OpenTimeout, Net::ReadTimeout => e
        raise NetworkError, "Request timed out: #{e.message}"
      rescue SocketError, Errno::ECONNREFUSED => e
        raise NetworkError, "Connection failed: #{e.message}"
      end

      def make_http_request(uri)
        Net::HTTP.start(uri.host, uri.port, use_ssl: uri.scheme == "https",
                                            read_timeout: REQUEST_TIMEOUT, open_timeout: 10) do |http|
          request = Net::HTTP::Get.new(uri)
          request["User-Agent"] = "RubyCode/#{RubyCode::VERSION}"
          http.request(request)
        end
      end

      def handle_response(response, uri, url)
        case response
        when Net::HTTPSuccess
          response.body.force_encoding("UTF-8")
        when Net::HTTPRedirection
          handle_redirect(response, uri, url)
        else
          raise HTTPError, "HTTP #{response.code}: #{response.message}"
        end
      end

      def handle_redirect(response, uri, url)
        location = response["location"]
        raise HTTPError, "Redirect loop detected" if location == url

        redirect_uri = build_redirect_uri(location, uri)
        fetch_url(redirect_uri.to_s)
      end

      def build_redirect_uri(location, base_uri)
        redirect_uri = URI.parse(location)
        redirect_uri.absolute? ? redirect_uri : base_uri + location
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
