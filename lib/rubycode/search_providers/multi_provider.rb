# frozen_string_literal: true

module RubyCode
  module SearchProviders
    # Multi-provider search with automatic fallback
    class MultiProvider
      def initialize(providers: [])
        @providers = providers
      end

      def search(query, max_results: 5)
        last_error = nil

        @providers.each do |provider|
          begin
            results = provider.search(query, max_results: max_results)
            return results if results && !results.empty?
          rescue StandardError => e
            last_error = e
            # Continue to next provider
          end
        end

        # If all providers failed, raise the last error
        raise last_error if last_error

        # If no error but no results, return empty array
        []
      end

      # Add a provider to the list
      def add_provider(provider)
        @providers << provider
      end

      # Get list of available providers
      def provider_names
        @providers.map { |p| p.class.name.split("::").last }
      end
    end
  end
end
