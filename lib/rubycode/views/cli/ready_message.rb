# frozen_string_literal: true

require "pastel"

module RubyCode
  module Views
    module Cli
      # Builds ready status message
      class ReadyMessage
        def self.build
          pastel = Pastel.new
          "\n#{pastel.green("✓")} #{pastel.bold("Ready!")} #{I18n.t("rubycode.cli.ready")}"
        end
      end
    end
  end
end
