# frozen_string_literal: true

require "net/http"
require "json"

module RubyCode
  module Adapters
    # Google Gemini adapter for cloud LLM integration
    # Gemini provides powerful multimodal models with long context windows
    class Gemini < Base
      API_ENDPOINT = "https://generativelanguage.googleapis.com/v1beta/models"

      def initialize(config)
        super
        validate_api_key!
      end

      def generate(messages:, system: nil, tools: nil)
        api_key = get_api_key
        # Gemini URL format: https://generativelanguage.googleapis.com/v1beta/models/{model}:generateContent
        uri = URI("https://generativelanguage.googleapis.com/v1beta/models/#{@config.model}:generateContent?key=#{api_key}")
        payload = build_payload(messages, system, tools)
        request = build_request(uri, payload)

        debug_request(uri, payload) if @config.debug

        body = send_request_with_retry(uri, request)

        debug_response(body) if @config.debug

        # Convert Gemini format to our format
        convert_response(body)
      end

      private

      def validate_api_key!
        return if get_api_key

        raise AdapterError, I18n.t("rubycode.errors.gemini.api_key_missing")
      end

      def get_api_key
        # Check database first
        db_key = Models::ApiKey.get_key(adapter: :gemini)
        return db_key if db_key

        # Fall back to environment variable
        ENV.fetch("GEMINI_API_KEY", nil)
      end

      def send_request_with_retry(uri, request)
        attempt = 0

        begin
          attempt += 1
          send_request(uri, request)
        rescue AdapterTimeoutError, AdapterConnectionError => e
          unless attempt <= @config.max_retries
            raise AdapterRetryExhaustedError,
                  I18n.t("rubycode.errors.adapter.retry_failed",
                         max_retries: @config.max_retries,
                         error: e.message)
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
        # Convert to Gemini format
        contents = messages.map do |msg|
          {
            role: msg[:role] == "assistant" ? "model" : "user",
            parts: [{ text: msg[:content] }]
          }
        end

        payload = { contents: contents }

        # Add system instruction if provided
        payload[:systemInstruction] = { parts: [{ text: system }] } if system

        # Add tools if provided
        payload[:tools] = convert_tools_to_gemini_format(tools) if tools

        payload
      end

      def convert_tools_to_gemini_format(tools)
        return nil unless tools

        [{
          functionDeclarations: tools.map do |tool|
            {
              name: tool.dig(:function, :name),
              description: tool.dig(:function, :description),
              parameters: tool.dig(:function, :parameters)
            }
          end
        }]
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
        raise AdapterError, I18n.t("rubycode.errors.adapter.invalid_json", error: e.message)
      rescue StandardError => e
        raise AdapterError, I18n.t("rubycode.errors.adapter.unexpected_error", error: e.message)
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
          raise AdapterTimeoutError,
                I18n.t("rubycode.errors.adapter.read_timeout",
                       timeout: @config.http_read_timeout,
                       error: error.message)
        when Net::OpenTimeout
          raise AdapterTimeoutError,
                I18n.t("rubycode.errors.adapter.open_timeout",
                       timeout: @config.http_open_timeout,
                       error: error.message)
        when Errno::ECONNREFUSED
          raise AdapterConnectionError,
                I18n.t("rubycode.errors.adapter.connection_refused",
                       uri: uri,
                       error: error.message)
        when Errno::ETIMEDOUT
          raise AdapterConnectionError,
                I18n.t("rubycode.errors.adapter.connection_timeout",
                       uri: uri,
                       error: error.message)
        when SocketError
          raise AdapterConnectionError,
                I18n.t("rubycode.errors.adapter.host_unreachable",
                       hostname: uri.hostname,
                       error: error.message)
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
          raise AdapterError,
                I18n.t("rubycode.errors.adapter.auth_failed",
                       code: response.code,
                       adapter_name: "GEMINI")
        when 429
          # Rate limit errors should be retried with backoff
          raise AdapterConnectionError,
                I18n.t("rubycode.errors.adapter.rate_limited",
                       code: response.code,
                       message: response.message)
        when 500..599
          # Server errors are retriable
          raise AdapterConnectionError,
                I18n.t("rubycode.errors.adapter.server_error",
                       code: response.code,
                       message: response.message)
        else
          # Client errors are not retriable
          raise AdapterError,
                I18n.t("rubycode.errors.adapter.http_error",
                       code: response.code,
                       message: response.message)
        end
      end

      def convert_response(gemini_response)
        # Gemini format: { candidates: [{ content: { parts: [...], role: "model" }, finishReason: "STOP" }] }
        # Our format: { "message" => { "content" => ..., "tool_calls" => [...] } }

        candidate = gemini_response["candidates"]&.first
        raise AdapterError, I18n.t("rubycode.errors.adapter.no_choices") unless candidate

        content_obj = candidate["content"]
        raise AdapterError, I18n.t("rubycode.errors.adapter.no_message") unless content_obj

        parts = content_obj["parts"] || []

        # Extract text content
        text_content = parts
                       .select { |p| p["text"] }
                       .map { |p| p["text"] }
                       .join("\n")

        # Extract function calls
        tool_calls = parts
                     .select { |p| p["functionCall"] }
                     .map { |p| convert_function_call(p["functionCall"]) }

        {
          "message" => {
            "content" => text_content,
            "tool_calls" => tool_calls
          }
        }
      end

      def convert_function_call(function_call)
        {
          "function" => {
            "name" => function_call["name"],
            "arguments" => function_call["args"] || {}
          }
        }
      end

      def debug_request(uri, payload)
        separator = I18n.t("rubycode.debug.separator")
        puts "\n#{separator}"
        puts I18n.t("rubycode.debug.request_title_adapter", adapter: "Gemini")
        puts separator
        puts I18n.t("rubycode.debug.url_label", url: uri.to_s.gsub(/key=.*/, "key=***"))
        puts I18n.t("rubycode.debug.model_label", model: @config.model)
        puts "\n#{I18n.t("rubycode.debug.payload_label")}"
        puts JSON.pretty_generate(payload)
        puts separator
      end

      def debug_response(body)
        separator = I18n.t("rubycode.debug.separator")
        puts "\n#{separator}"
        puts I18n.t("rubycode.debug.response_title_adapter", adapter: "Gemini")
        puts separator
        puts JSON.pretty_generate(body)
        puts "#{separator}\n"
      end
    end
  end
end
