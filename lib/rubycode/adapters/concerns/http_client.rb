# frozen_string_literal: true

module RubyCode
  module Adapters
    module Concerns
      # HTTP client with retry logic for adapters
      module HttpClient
        private

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
            use_ssl: use_ssl?(uri),
            read_timeout: @config.http_read_timeout,
            open_timeout: @config.http_open_timeout
          ) { |http| http.request(request) }
        end

        def use_ssl?(uri)
          uri.scheme == "https"
        end
      end
    end
  end
end
