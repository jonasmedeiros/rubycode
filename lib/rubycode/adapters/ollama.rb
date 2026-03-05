# frozen_string_literal: true

require "net/http"
require "json"

module RubyCode
  module Adapters
    # Ollama adapter for local LLM integration
    class Ollama < Base
      def generate(messages:, system: nil, tools: nil)
        uri = URI("#{@config.url}/api/chat")
        payload = build_payload(messages, system, tools)
        request = build_request(uri, payload)

        debug_request(uri, payload) if @config.debug

        body = send_request_with_retry(uri, request)

        debug_response(body) if @config.debug

        body
      end

      private

      def send_request_with_retry(uri, request)
        attempt = 0

        begin
          attempt += 1
          send_request(uri, request)
        rescue AdapterTimeoutError, AdapterConnectionError => e
          unless attempt <= @config.max_retries
            raise AdapterRetryExhaustedError, "Failed after #{@config.max_retries} retries: #{e.message}"
          end

          delay = @config.retry_base_delay * (2**(attempt - 1))
          display_retry_status(attempt, @config.max_retries, delay, e)
          sleep(delay)
          retry
        end
      end

      def display_retry_status(attempt, max_retries, delay, error)
        puts Views::AgentLoop::RetryStatus.build(
          attempt: attempt,
          max_retries: max_retries,
          delay: delay,
          error: error.message
        )
      end

      def build_payload(messages, system, tools)
        payload = { model: @config.model, messages: messages, stream: false }
        payload[:system] = system if system
        payload[:tools] = tools if tools
        payload
      end

      def build_request(uri, payload)
        request = Net::HTTP::Post.new(uri)
        request["Content-Type"] = "application/json"
        request.body = payload.to_json
        request
      end

      def send_request(uri, request)
        response = perform_http_request(uri, request)
        handle_response(response)
      rescue Net::ReadTimeout, Net::OpenTimeout, Errno::ECONNREFUSED, Errno::ETIMEDOUT, SocketError => e
        handle_network_error(e, uri)
      rescue JSON::ParserError => e
        raise AdapterError, "Invalid JSON response from server: #{e.message}"
      rescue StandardError => e
        raise AdapterError, "Unexpected error: #{e.message}"
      end

      def perform_http_request(uri, request)
        Net::HTTP.start(
          uri.hostname,
          uri.port,
          read_timeout: @config.http_read_timeout,
          open_timeout: @config.http_open_timeout
        ) { |http| http.request(request) }
      end

      def handle_network_error(error, uri)
        case error
        when Net::ReadTimeout
          raise AdapterTimeoutError, "Request timed out after #{@config.http_read_timeout}s: #{error.message}"
        when Net::OpenTimeout
          raise AdapterTimeoutError, "Connection timed out after #{@config.http_open_timeout}s: #{error.message}"
        when Errno::ECONNREFUSED
          raise AdapterConnectionError, "Connection refused to #{uri}: #{error.message}"
        when Errno::ETIMEDOUT
          raise AdapterConnectionError, "Connection timed out to #{uri}: #{error.message}"
        when SocketError
          raise AdapterConnectionError, "Cannot resolve host #{uri.hostname}: #{error.message}"
        end
      end

      def handle_response(response)
        body = JSON.parse(response.body)

        # Check for HTTP errors
        case response.code.to_i
        when 200..299
          body
        when 500..599
          # Server errors are retriable
          raise AdapterConnectionError, "Server error (#{response.code}): #{response.message}"
        else
          # Client errors are not retriable
          raise AdapterError, "HTTP error (#{response.code}): #{response.message}"
        end
      end

      def debug_request(uri, payload)
        puts "\n#{"=" * 80}"
        puts "📤 REQUEST TO LLM"
        puts "=" * 80
        puts "URL: #{uri}"
        puts "Model: #{@config.model}"
        puts "\nPayload:"
        puts JSON.pretty_generate(payload)
        puts "=" * 80
      end

      def debug_response(body)
        puts "\n#{"=" * 80}"
        puts "📥 RESPONSE FROM LLM"
        puts "=" * 80
        puts JSON.pretty_generate(body)
        puts "#{"=" * 80}\n"
      end
    end
  end
end
