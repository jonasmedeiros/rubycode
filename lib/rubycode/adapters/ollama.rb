# frozen_string_literal: true

require "net/http"
require "json"

module RubyCode
  module Adapters
    # Ollama adapter for cloud LLM integration
    class Ollama < Base
      def initialize(config)
        super
        validate_api_key!
      end

      def generate(messages:, system: nil, tools: nil)
        enforce_rate_limit_delay

        uri = build_uri
        payload = build_payload(messages, system, tools)
        request = build_request(uri, payload)

        debug_request(uri, payload) if @config.debug

        body = send_request_with_retry(uri, request)

        debug_response(body) if @config.debug

        @last_request_time = Time.now

        # Extract and track tokens
        @current_request_tokens = extract_tokens(body)
        @total_tokens_counter += @current_request_tokens

        body
      rescue AdapterError => e
        # If model doesn't support tools, provide helpful error message
        raise AdapterError, build_tools_error_message if tools && e.message.include?("does not support tools")

        raise e
      end

      private

      def adapter_name
        "Ollama"
      end

      def api_endpoint
        # Not used - Ollama uses build_uri override
        "#{@config.url}/api/chat"
      end

      def build_uri
        URI("#{@config.url}/api/chat")
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
        request["Authorization"] = "Bearer #{api_key}"
        request.body = payload.to_json
        request
      end

      def convert_response(_raw_response)
        # Ollama returns the body directly in the right format
        # No conversion needed
        raise NotImplementedError, "Ollama doesn't use convert_response"
      end

      def send_request(uri, request)
        response = perform_http_request(uri, request)
        body = handle_response(response)

        # Parse tool calls from content for models that use XML format (like Qwen)
        parse_tool_calls_from_content(body) if body["message"]

        body
      rescue Net::ReadTimeout, Net::OpenTimeout, Errno::ECONNREFUSED, Errno::ETIMEDOUT, SocketError => e
        handle_network_error(e, uri)
      rescue JSON::ParserError => e
        raise AdapterError, I18n.t("rubycode.errors.adapter.invalid_json", error: e.message)
      rescue StandardError => e
        raise AdapterError, I18n.t("rubycode.errors.adapter.unexpected_error", error: e.message)
      end

      def build_tools_error_message
        I18n.t("rubycode.errors.tools_not_supported", model: @config.model)
      end

      # Parse <tool_call> XML tags or plain JSON from message content
      # Some models (like Qwen) return tool calls as XML or JSON in content instead of structured format
      def parse_tool_calls_from_content(body)
        message = body["message"]
        content = message["content"] || ""

        return if content.empty?

        tool_calls = []
        clean_content = content.dup

        # Try parsing XML-wrapped tool calls first: <tool_call>{"name": "...", "arguments": {...}}</tool_call>
        if content.include?("<tool_call>")
          content.scan(%r{<tool_call>(.*?)</tool_call>}m) do |match|
            tool_call_json = match[0].strip
            tool_data = parse_tool_json(tool_call_json)
            tool_calls << convert_to_openai_format(tool_data) if tool_data
          end

          # Remove all <tool_call> blocks from content
          clean_content = content.gsub(%r{<tool_call>.*?</tool_call>}m, "").strip if tool_calls.any?
        end

        # Try parsing plain JSON tool call: {"name": "...", "arguments": {...}}
        if tool_calls.empty? && content.strip.start_with?("{") && (tool_data = parse_tool_json(content))
          tool_calls << convert_to_openai_format(tool_data)
          clean_content = "" # Content was a tool call, clear it
        end

        # Update message with parsed tool calls and cleaned content
        return unless tool_calls.any?

        message["tool_calls"] = tool_calls
        message["content"] = clean_content
      end

      def parse_tool_json(json_string)
        JSON.parse(json_string)
      rescue JSON::ParserError
        nil
      end

      def convert_to_openai_format(tool_data)
        {
          "function" => {
            "name" => tool_data["name"],
            "arguments" => tool_data["arguments"]
          }
        }
      end

      def extract_tokens(response_body)
        # Ollama returns tokens in different format
        TokenCounter.new(
          input: response_body["prompt_eval_count"],
          output: response_body["eval_count"]
        )
      end
    end
  end
end
