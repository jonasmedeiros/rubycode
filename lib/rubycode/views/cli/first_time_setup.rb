# frozen_string_literal: true

require "pastel"

module RubyCode
  module Views
    module Cli
      # Builds first time setup message
      class FirstTimeSetup
        def self.build
          pastel = Pastel.new
          "\n#{pastel.green(I18n.t("rubycode.setup.first_time"))}\n"
        end
      end
    end
  end
end
