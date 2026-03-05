# frozen_string_literal: true

require "pastel"

module RubyCode
  module Views
    module Cli
      # Builds goodbye/exit message
      class ExitMessage
        def self.build
          pastel = Pastel.new
          "\n#{pastel.green(I18n.t("rubycode.cli.exit"))}\n"
        end
      end
    end
  end
end
