# frozen_string_literal: true

require "pastel"

module RubyCode
  module Views
    module Cli
      # Builds setup wizard title
      class SetupTitle
        def self.build
          pastel = Pastel.new
          "\n#{pastel.bold(I18n.t("rubycode.setup.title"))}\n\n"
        end
      end
    end
  end
end
