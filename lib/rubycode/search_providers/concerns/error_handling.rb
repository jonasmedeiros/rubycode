# frozen_string_literal: true

module RubyCode
  module SearchProviders
    module Concerns
      # Error handling for search providers
      module ErrorHandling
        private

        def handle_network_error(error, uri)
          error_key = network_error_key(error)
          error_params = build_network_error_params(error, uri)
          raise SearchProviderError, I18n.t("rubycode.errors.search_provider.#{error_key}", error_params)
        end

        def network_error_key(error)
          case error
          when Net::ReadTimeout then :read_timeout
          when Net::OpenTimeout then :open_timeout
          when Errno::ECONNREFUSED then :connection_refused
          when Errno::ETIMEDOUT then :connection_timeout
          when SocketError then :host_unreachable
          end
        end

        def build_network_error_params(error, uri)
          base_params = { provider: provider_name, error: error.message }
          case error
          when Net::ReadTimeout
            base_params.merge(timeout: http_read_timeout)
          when Net::OpenTimeout
            base_params.merge(timeout: http_open_timeout)
          when Errno::ECONNREFUSED, Errno::ETIMEDOUT
            base_params.merge(uri: uri)
          when SocketError
            base_params.merge(hostname: uri.hostname)
          else
            base_params
          end
        end

        def handle_http_error(response)
          code = response.code.to_i
          return response if code.between?(200, 299)

          error_key = http_error_key(code)
          raise SearchProviderError,
                I18n.t("rubycode.errors.search_provider.#{error_key}",
                       code: response.code,
                       provider: provider_name)
        end

        def http_error_key(code)
          case code
          when 401, 403 then :auth_failed
          when 429 then :rate_limited
          when 500..599 then :server_error
          else :http_error
          end
        end
      end
    end
  end
end
