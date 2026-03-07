# frozen_string_literal: true

require_relative "concerns/error_handling"
require_relative "concerns/http_client"
require_relative "concerns/debugging"

module RubyCode
  module Adapters
    # Base adapter class for LLM integrations
    class Base
      include Concerns::ErrorHandling
      include Concerns::HttpClient
      include Concerns::Debugging

      def initialize(config)
        @config = config
      end

      def generate(messages:, system: nil, tools: nil)
        uri = build_uri
        payload = build_payload(messages, system, tools)
        request = build_request(uri, payload)

        debug_request(uri, payload) if @config.debug

        body = send_request_with_retry(uri, request)

        debug_response(body) if @config.debug

        convert_response(body)
      end

      private

      # Abstract methods to be implemented by subclasses
      def adapter_name
        raise NotImplementedError, "Subclass must define adapter_name"
      end

      def build_payload(_messages, _system, _tools)
        raise NotImplementedError, "Subclass must define build_payload"
      end

      def build_request(_uri, _payload)
        raise NotImplementedError, "Subclass must define build_request"
      end

      def convert_response(_raw_response)
        raise NotImplementedError, "Subclass must define convert_response"
      end

      def api_endpoint
        raise NotImplementedError, "Subclass must define api_endpoint"
      end

      # Concrete shared methods
      def api_key
        # Check database first
        db_key = Models::ApiKey.get_key(adapter: adapter_symbol)
        return db_key if db_key

        # Fall back to environment variable
        ENV.fetch("#{adapter_name.upcase}_API_KEY", nil)
      end

      def adapter_symbol
        # Convert class name to symbol: Openai -> :openai
        self.class.name.split("::").last.downcase.to_sym
      end

      def validate_api_key!
        return if api_key

        raise AdapterError, I18n.t("rubycode.errors.#{adapter_symbol}.api_key_missing")
      end

      def build_uri
        URI(api_endpoint)
      end
    end
  end
end
