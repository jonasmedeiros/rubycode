# frozen_string_literal: true

require "net/http"
require "json"

module RubyCode
  module Adapters
    # OpenAI adapter for cloud LLM integration
    # OpenAI provides industry-leading models including GPT-4o
    class Openai < Base
      API_ENDPOINT = "https://api.openai.com/v1/chat/completions"

      def initialize(config)
        super
        validate_api_key!
      end

      private

      def adapter_name
        "OpenAI"
      end

      def api_endpoint
        API_ENDPOINT
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

        # OpenAI supports function calling format
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

      def convert_response(openai_response)
        # OpenAI format: { choices: [{ message: { role, content, tool_calls } }] }
        # Our format: { "message" => { "content" => ..., "tool_calls" => [...] } }

        choice = openai_response["choices"]&.first
        raise AdapterError, I18n.t("rubycode.errors.adapter.no_choices") unless choice

        message = choice["message"]
        raise AdapterError, I18n.t("rubycode.errors.adapter.no_message") unless message

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

      def extract_tokens(response_body)
        usage = response_body["usage"] || {}

        TokenCounter.new(
          input: usage["prompt_tokens"],
          output: usage["completion_tokens"],
          cached: usage.dig("prompt_tokens_details", "cached_tokens"),
          thinking: usage.dig("completion_tokens_details", "reasoning_tokens")
        )
      end
    end
  end
end
