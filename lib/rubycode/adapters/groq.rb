# frozen_string_literal: true

require "net/http"
require "json"

module RubyCode
  module Adapters
    # Groq adapter for cloud LLM integration (OpenAI-compatible API)
    class Groq < Base
      API_ENDPOINT = "https://api.groq.com/openai/v1/chat/completions"

      def initialize(config)
        super
        validate_api_key!
      end

      def generate(messages:, system: nil, tools: nil)
        uri = URI(API_ENDPOINT)
        payload = build_payload(messages, system, tools)
        request = build_request(uri, payload)

        debug_request(uri, payload) if @config.debug

        body = send_request_with_retry(uri, request)

        debug_response(body) if @config.debug

        # Convert OpenAI format to our format
        convert_response(body)
      end

      private

      def validate_api_key!
        return if ENV["GROQ_API_KEY"]

        raise AdapterError, <<~ERROR
          GROQ_API_KEY environment variable not set.

          Get your API key:
            https://console.groq.com/keys

          Then set it:
            export GROQ_API_KEY='gsk_...'
        ERROR
      end

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
        # OpenAI format: system message goes in messages array
        formatted_messages = messages.dup

        formatted_messages.unshift({ role: "system", content: system }) if system

        payload = {
          model: @config.model,
          messages: formatted_messages,
          temperature: 0.7
        }

        # Groq supports OpenAI function calling format
        payload[:tools] = tools if tools

        payload
      end

      def build_request(uri, payload)
        request = Net::HTTP::Post.new(uri)
        request["Content-Type"] = "application/json"
        request["Authorization"] = "Bearer #{ENV.fetch("GROQ_API_KEY", nil)}"
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
          use_ssl: true,
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
        when 401, 403
          # Auth errors are not retriable
          raise AdapterError, "Authentication failed (#{response.code}): Check your GROQ_API_KEY"
        when 429
          # Rate limit errors should be retried with backoff
          raise AdapterConnectionError, "Rate limited (#{response.code}): #{response.message}"
        when 500..599
          # Server errors are retriable
          raise AdapterConnectionError, "Server error (#{response.code}): #{response.message}"
        else
          # Client errors are not retriable
          raise AdapterError, "HTTP error (#{response.code}): #{response.message}"
        end
      end

      def convert_response(openai_response)
        # OpenAI format: { choices: [{ message: { role, content, tool_calls } }] }
        # Our format: { "message" => { "content" => ..., "tool_calls" => [...] } }

        choice = openai_response["choices"]&.first
        raise AdapterError, "No choices in response" unless choice

        message = choice["message"]
        raise AdapterError, "No message in choice" unless message

        {
          "message" => {
            "content" => message["content"] || "",
            "tool_calls" => format_tool_calls(message["tool_calls"])
          }
        }
      end

      def format_tool_calls(openai_tool_calls)
        return [] unless openai_tool_calls

        openai_tool_calls.map do |tool_call|
          {
            "function" => {
              "name" => tool_call.dig("function", "name"),
              "arguments" => tool_call.dig("function", "arguments")
            }
          }
        end
      end

      def debug_request(uri, payload)
        puts "\n#{"=" * 80}"
        puts "📤 REQUEST TO LLM (Groq)"
        puts "=" * 80
        puts "URL: #{uri}"
        puts "Model: #{@config.model}"
        puts "\nPayload:"
        puts JSON.pretty_generate(payload)
        puts "=" * 80
      end

      def debug_response(body)
        puts "\n#{"=" * 80}"
        puts "📥 RESPONSE FROM LLM (Groq)"
        puts "=" * 80
        puts JSON.pretty_generate(body)
        puts "#{"=" * 80}\n"
      end
    end
  end
end
