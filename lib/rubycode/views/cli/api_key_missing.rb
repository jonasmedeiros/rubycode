# frozen_string_literal: true

require "tty-box"
require "pastel"

module RubyCode
  module Views
    module Cli
      # Builds API key missing warning
      class ApiKeyMissing
        def self.build(adapter:)
          Pastel.new
          adapter_upper = adapter.to_s.upcase
          adapter_info = I18n.t("rubycode.adapters.#{adapter}")

          warning_box = TTY::Box.frame(
            title: { top_left: " ⚠️  #{I18n.t("rubycode.setup.api_key_missing", adapter: adapter_upper)} " },
            border: :thick,
            padding: 1,
            style: {
              fg: :yellow,
              border: {
                fg: :yellow
              }
            }
          ) do
            I18n.t("rubycode.setup.api_key_help",
                   url: adapter_info[:api_key_url],
                   env_var: "#{adapter_upper}_API_KEY")
          end

          "\n#{warning_box}"
        end
      end
    end
  end
end
