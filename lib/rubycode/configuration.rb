# frozen_string_literal: true

module Rubycode
  class Configuration
    attr_accessor :adapter, :url, :model, :root_path, :debug, :enable_tool_injection_workaround

    def initialize
      @adapter = :ollama
      @url = "http://localhost:11434"
      @model = "qwen3-coder:480b-cloud"
      @root_path = Dir.pwd
      @debug = false # Set to true to see JSON requests/responses

      # WORKAROUND for weak tool-calling models (qwen3-coder, etc.)
      # When enabled, injects reminder messages if model generates text instead of calling tools
      # OpenCode does NOT use this - they rely on strong tool-calling models (Claude, GPT-4)
      # Set to true ONLY for testing with weak models
      @enable_tool_injection_workaround = false
    end
  end
end
