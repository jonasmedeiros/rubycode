# frozen_string_literal: true

module Rubycode
  class ContextBuilder
    def initialize(root_path:)
      @root_path = root_path
    end

    def environment_context
      <<~CONTEXT
        <env>
        Working directory: #{@root_path}
        Platform: #{RUBY_PLATFORM}
        Ruby version: #{RUBY_VERSION}
        Today's date: #{Time.now.strftime("%Y-%m-%d")}
        </env>
      CONTEXT
    end
  end
end
