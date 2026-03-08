# frozen_string_literal: true

require "pastel"

module RubyCode
  module Views
    module Cli
      # Builds restart message
      class RestartMessage
        def self.build
          pastel = Pastel.new
          "\n#{pastel.yellow(I18n.t("rubycode.setup.restart_message"))}\n"
        end
      end
    end
  end
end
