# frozen_string_literal: true

module RubyCode
  module SearchProviders
    module Concerns
      # Error handling for search providers
      module ErrorHandling
        private

        def handle_network_error(error, uri)
          case error
          when Net::ReadTimeout
            raise SearchProviderError,
                  I18n.t("rubycode.errors.search_provider.read_timeout",
                         timeout: http_read_timeout,
                         provider: provider_name,
                         error: error.message)
          when Net::OpenTimeout
            raise SearchProviderError,
                  I18n.t("rubycode.errors.search_provider.open_timeout",
                         timeout: http_open_timeout,
                         provider: provider_name,
                         error: error.message)
          when Errno::ECONNREFUSED
            raise SearchProviderError,
                  I18n.t("rubycode.errors.search_provider.connection_refused",
                         uri: uri,
                         provider: provider_name,
                         error: error.message)
          when Errno::ETIMEDOUT
            raise SearchProviderError,
                  I18n.t("rubycode.errors.search_provider.connection_timeout",
                         uri: uri,
                         provider: provider_name,
                         error: error.message)
          when SocketError
            raise SearchProviderError,
                  I18n.t("rubycode.errors.search_provider.host_unreachable",
                         hostname: uri.hostname,
                         provider: provider_name,
                         error: error.message)
          end
        end

        def handle_http_error(response)
          case response.code.to_i
          when 200..299
            response
          when 401, 403
            raise SearchProviderError,
                  I18n.t("rubycode.errors.search_provider.auth_failed",
                         code: response.code,
                         provider: provider_name)
          when 429
            raise SearchProviderError,
                  I18n.t("rubycode.errors.search_provider.rate_limited",
                         code: response.code,
                         provider: provider_name)
          when 500..599
            raise SearchProviderError,
                  I18n.t("rubycode.errors.search_provider.server_error",
                         code: response.code,
                         provider: provider_name)
          else
            raise SearchProviderError,
                  I18n.t("rubycode.errors.search_provider.http_error",
                         code: response.code,
                         provider: provider_name)
          end
        end
      end
    end
  end
end
