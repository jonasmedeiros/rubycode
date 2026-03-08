# frozen_string_literal: true

module RubyCode
  module Adapters
    module Concerns
      # Error handling for adapter HTTP responses
      module ErrorHandling
        private

        def handle_network_error(error, uri)
          case error
          when Net::ReadTimeout
            raise_timeout_error(:read_timeout, @config.http_read_timeout, error)
          when Net::OpenTimeout
            raise_timeout_error(:open_timeout, @config.http_open_timeout, error)
          when Errno::ECONNREFUSED
            raise_connection_error(:connection_refused, uri, error)
          when Errno::ETIMEDOUT
            raise_connection_error(:connection_timeout, uri, error)
          when SocketError
            raise AdapterConnectionError,
                  I18n.t("rubycode.errors.adapter.host_unreachable",
                         hostname: uri.hostname,
                         error: error.message)
          end
        end

        def raise_timeout_error(key, timeout, error)
          raise AdapterTimeoutError,
                I18n.t("rubycode.errors.adapter.#{key}",
                       timeout: timeout,
                       error: error.message)
        end

        def raise_connection_error(key, uri, error)
          raise AdapterConnectionError,
                I18n.t("rubycode.errors.adapter.#{key}",
                       uri: uri,
                       error: error.message)
        end

        def handle_response(response)
          body = JSON.parse(response.body)

          case response.code.to_i
          when 200..299
            body
          when 401, 403
            raise_auth_error(response.code)
          when 429
            raise_rate_limit_error(response)
          when 500..599
            raise_server_error(response)
          else
            raise_http_error(response)
          end
        end

        def raise_auth_error(code)
          raise AdapterError,
                I18n.t("rubycode.errors.adapter.auth_failed",
                       code: code,
                       adapter_name: adapter_name.upcase)
        end

        def raise_rate_limit_error(response)
          raise AdapterConnectionError,
                I18n.t("rubycode.errors.adapter.rate_limited",
                       code: response.code,
                       message: response.message)
        end

        def raise_server_error(response)
          raise AdapterConnectionError,
                I18n.t("rubycode.errors.adapter.server_error",
                       code: response.code,
                       message: response.message)
        end

        def raise_http_error(response)
          raise AdapterError,
                I18n.t("rubycode.errors.adapter.http_error",
                       code: response.code,
                       message: response.message)
        end
      end
    end
  end
end
