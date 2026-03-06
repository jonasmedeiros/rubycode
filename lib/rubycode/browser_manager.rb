# frozen_string_literal: true

require "ferrum"

module RubyCode
  # Manages a singleton Ferrum browser instance for web tools
  module BrowserManager
    @mutex = Mutex.new

    class << self
      # Get or create the shared browser instance
      def browser
        @mutex.synchronize { @browser ||= create_browser }
      end

      # Reset the browser (quit and clear instance)
      def reset!
        @browser&.quit
        @browser = nil
      end

      private

      def create_browser
        Ferrum::Browser.new(
          headless: true,
          timeout: 30,
          process_timeout: 10,
          window_size: [1920, 1080],
          browser_options: {
            "no-sandbox": nil,
            "disable-gpu": nil
          }
        )
      end
    end
  end
end

# Cleanup browser on exit
at_exit { RubyCode::BrowserManager.reset! }
