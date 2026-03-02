# frozen_string_literal: true

module RubyCode
  # Configuration class for Rubycode settings
  class Configuration
    attr_accessor :adapter, :url, :model, :root_path, :debug, :enable_tool_injection_workaround

    def initialize
      @adapter = :ollama
      @url = "http://localhost:11434"
      @model = "deepseek-v3.1:671b-cloud"
      @root_path = Dir.pwd
      @debug = false # Set to true to see JSON requests/responses

      # WORKAROUND for weak tool-calling models
      # When enabled, injects reminder messages if model generates text instead of calling tools
      # Set to true ONLY for testing with weak models
      @enable_tool_injection_workaround = false
    end
  end
end
