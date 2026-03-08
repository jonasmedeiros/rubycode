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

      private

      def adapter_name
        "Gemini"
      end

      def api_endpoint
        # Gemini embeds API key in URL
        "https://generativelanguage.googleapis.com/v1beta/models/#{@config.model}:generateContent?key=#{api_key}"
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

      def convert_response(gemini_response)
        # Gemini format: { candidates: [{ content: { parts: [...], role: "model" }, finishReason: "STOP" }] }
        # Our format: { "message" => { "content" => ..., "tool_calls" => [...] } }

        parts = extract_parts_from_response(gemini_response)

        {
          "message" => {
            "content" => extract_text_content(parts),
            "tool_calls" => extract_tool_calls(parts)
          }
        }
      end

      def extract_parts_from_response(gemini_response)
        candidate = gemini_response["candidates"]&.first
        raise AdapterError, I18n.t("rubycode.errors.adapter.no_choices") unless candidate

        content_obj = candidate["content"]
        raise AdapterError, I18n.t("rubycode.errors.adapter.no_message") unless content_obj

        content_obj["parts"] || []
      end

      def extract_text_content(parts)
        parts
          .select { |p| p["text"] }
          .map { |p| p["text"] }
          .join("\n")
      end

      def extract_tool_calls(parts)
        parts
          .select { |p| p["functionCall"] }
          .map { |p| convert_function_call(p["functionCall"]) }
      end

      def convert_function_call(function_call)
        {
          "function" => {
            "name" => function_call["name"],
            "arguments" => function_call["args"] || {}
          }
        }
      end

      def extract_tokens(response_body)
        usage = response_body["usageMetadata"] || {}
        candidates = usage["candidatesTokenCount"] || 0
        thoughts = usage["thoughtsTokenCount"] || 0

        TokenCounter.new(
          input: usage["promptTokenCount"],
          output: candidates + thoughts, # Must sum both
          thinking: thoughts
        )
      end

      def sanitize_url(uri)
        uri.to_s.gsub(/key=[^&]*/, "key=***")
      end
    end
  end
end
