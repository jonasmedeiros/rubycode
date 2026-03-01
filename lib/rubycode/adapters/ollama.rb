# frozen_string_literal: true

require "net/http"
require "json"

module Rubycode
  module Adapters
    class Ollama < Base
      def generate(messages:, system: nil, tools: nil)
        uri = URI("#{@config.url}/api/chat")
        payload = build_payload(messages, system, tools)
        request = build_request(uri, payload)

        debug_request(uri, payload) if @config.debug

        body = send_request(uri, request)

        debug_response(body) if @config.debug

        body
      end

      private

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
        response = Net::HTTP.start(uri.hostname, uri.port) { |http| http.request(request) }
        JSON.parse(response.body)
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
