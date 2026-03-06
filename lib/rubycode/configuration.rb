# frozen_string_literal: true

module RubyCode
  # Configuration class for Rubycode settings
  class Configuration
    attr_accessor :adapter, :url, :model, :root_path, :debug, :enable_tool_injection_workaround,
                  :http_read_timeout, :http_open_timeout, :max_retries, :retry_base_delay

    def initialize
      @adapter = :ollama
      @url = "http://localhost:11434"
      @model = "deepseek-r1:8b"
      @root_path = Dir.pwd
      @debug = false # Set to true to see JSON requests/responses

      # WORKAROUND for models that don't follow tool-calling instructions
      # When enabled, injects reminder messages if model generates text instead of calling tools
      # Enabled by default as most models need this nudge
      @enable_tool_injection_workaround = true

      # HTTP timeout and retry configuration
      @http_read_timeout = 120 # 2 minutes for LLM inference
      @http_open_timeout = 10  # 10 seconds for connection
      @max_retries = 3         # Number of retries (4 total attempts)
      @retry_base_delay = 2.0  # Base delay for exponential backoff
    end

    # Load configuration from a hash
    # @param hash [Hash] Configuration hash with symbolized keys
    def load_from_hash(hash)
      @adapter = hash[:adapter] if hash.key?(:adapter)
      @model = hash[:model] if hash.key?(:model)
      @url = hash[:url] if hash.key?(:url)
      @debug = hash[:debug] if hash.key?(:debug)
      @root_path = hash[:root_path] if hash.key?(:root_path)
    end
  end
end
