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

      # WORKAROUND for models that don't follow tool-calling instructions
      # When enabled, injects reminder messages if model generates text instead of calling tools
      # Enabled by default as most models need this nudge
      @enable_tool_injection_workaround = true
    end
  end
end
