# frozen_string_literal: true

require "pastel"

module RubyCode
  module Views
    # Builds web search approval prompt display
    class WebSearchApproval
      def self.build(query:, max_results:)
        pastel = Pastel.new

        [
          "",
          pastel.cyan("━" * 80),
          pastel.bold.cyan("🔍 Web Search Request"),
          "#{pastel.cyan("Query:")} #{query}",
          "#{pastel.cyan("Max results:")} #{max_results}",
          pastel.cyan("─" * 80),
          pastel.yellow("This will make HTTP requests to:"),
          pastel.dim("  • DuckDuckGo Instant Answer API (free)"),
          pastel.dim("  • Brave Search API (if BRAVE_API_KEY is set)"),
          pastel.dim("  • Each result URL (HEAD request to verify)"),
          "",
          pastel.cyan("━" * 80)
        ].join("\n")
      end
    end
  end
end
