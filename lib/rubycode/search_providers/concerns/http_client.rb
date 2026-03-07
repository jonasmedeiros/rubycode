# frozen_string_literal: true

require "net/http"

module RubyCode
  module SearchProviders
    module Concerns
      # HTTP client for search providers
      module HttpClient
        private

        def make_http_request(uri_or_request)
          if uri_or_request.is_a?(URI)
            make_http_request_from_uri(uri_or_request)
          elsif uri_or_request.is_a?(Hash) && uri_or_request[:uri] && uri_or_request[:request]
            make_http_request_with_custom_request(uri_or_request[:uri], uri_or_request[:request])
          else
            raise ArgumentError, "Expected URI or {uri:, request:} hash"
          end
        end

        def make_http_request_from_uri(uri)
          Net::HTTP.start(
            uri.host,
            uri.port,
            use_ssl: uri.scheme == "https",
            read_timeout: http_read_timeout,
            open_timeout: http_open_timeout
          ) do |http|
            request = Net::HTTP::Get.new(uri)
            request["Accept"] = "application/json"
            request["User-Agent"] = "RubyCode/#{RubyCode::VERSION}"
            http.request(request)
          end
        rescue Net::ReadTimeout, Net::OpenTimeout, Errno::ECONNREFUSED, Errno::ETIMEDOUT, SocketError => e
          handle_network_error(e, uri)
        rescue StandardError => e
          raise SearchProviderError, "HTTP request failed: #{e.message}"
        end

        def make_http_request_with_custom_request(uri, request)
          Net::HTTP.start(
            uri.host,
            uri.port,
            use_ssl: uri.scheme == "https",
            read_timeout: http_read_timeout,
            open_timeout: http_open_timeout
          ) do |http|
            http.request(request)
          end
        rescue Net::ReadTimeout, Net::OpenTimeout, Errno::ECONNREFUSED, Errno::ETIMEDOUT, SocketError => e
          handle_network_error(e, uri)
        rescue StandardError => e
          raise SearchProviderError, "HTTP request failed: #{e.message}"
        end

        def http_read_timeout
          @config&.http_read_timeout || 10
        end

        def http_open_timeout
          @config&.http_open_timeout || 10
        end
      end
    end
  end
end
