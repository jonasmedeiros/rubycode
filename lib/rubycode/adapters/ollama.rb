# frozen_string_literal: true

require "net/http"
require "json"

module Rubycode
  module Adapters
    class Ollama < Base
      def generate(messages:, system: nil, tools: nil)
        uri = URI("#{@config.url}/api/chat")

        request = Net::HTTP::Post.new(uri)
        request["Content-Type"] = "application/json"

        payload = {
          model: @config.model,
          messages: messages,
          stream: false
        }
        payload[:system] = system if system
        payload[:tools] = tools if tools

        request.body = payload.to_json

        # DEBUG: Show request if debug mode enabled
        if @config.debug
          puts "\n" + "=" * 80
          puts "📤 REQUEST TO LLM"
          puts "=" * 80
          puts "URL: #{uri}"
          puts "Model: #{@config.model}"
          puts "\nPayload:"
          puts JSON.pretty_generate(payload)
          puts "=" * 80
        end

        response = Net::HTTP.start(uri.hostname, uri.port) do |http|
          http.request(request)
        end

        body = JSON.parse(response.body)

        # DEBUG: Show response if debug mode enabled
        if @config.debug
          puts "\n" + "=" * 80
          puts "📥 RESPONSE FROM LLM"
          puts "=" * 80
          puts JSON.pretty_generate(body)
          puts "=" * 80 + "\n"
        end

        # /api/chat always returns this structure:
        # { "message": { "role": "assistant", "content": "...", "tool_calls": [...] } }
        body
      end
    end
  end
end
