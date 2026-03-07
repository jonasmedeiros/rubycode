# frozen_string_literal: true

require "pastel"

module RubyCode
  module Views
    module Cli
      # Builds configuration saved message
      class ConfigSaved
        def self.build(path: "~/.rubycode/config.yml")
          pastel = Pastel.new
          "\n#{pastel.green("✓")} #{I18n.t("rubycode.setup.config_saved", path: path)}\n"
        end
      end
    end
  end
end
