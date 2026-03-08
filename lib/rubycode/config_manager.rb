# frozen_string_literal: true

require "yaml"
require "fileutils"

module RubyCode
  # Manages configuration persistence to ~/.rubycode/config.yml
  class ConfigManager
    CONFIG_DIR = File.join(Dir.home, ".rubycode")
    CONFIG_FILE = File.join(CONFIG_DIR, "config.yml")

    class << self
      # Load configuration from file
      # Returns hash with symbolized keys or nil if file doesn't exist
      def load
        return nil unless exists?

        yaml_content = File.read(CONFIG_FILE)
        config_hash = YAML.safe_load(yaml_content, permitted_classes: [Symbol])

        # Symbolize keys
        symbolize_keys(config_hash)
      rescue StandardError => e
        warn "Warning: Failed to load config from #{CONFIG_FILE}: #{e.message}"
        nil
      end

      # Save configuration to file
      # @param config_hash [Hash] Configuration hash to save
      def save(config_hash)
        FileUtils.mkdir_p(CONFIG_DIR)

        File.write(CONFIG_FILE, config_hash.to_yaml)
        true
      rescue StandardError => e
        warn "Warning: Failed to save config to #{CONFIG_FILE}: #{e.message}"
        false
      end

      # Check if config file exists
      # @return [Boolean]
      def exists?
        File.exist?(CONFIG_FILE)
      end

      # Get default configuration for a given adapter
      # @param adapter [Symbol] The adapter name (:ollama, :groq)
      # @return [Hash] Default configuration
      def defaults_for_adapter(adapter)
        case adapter
        when :groq
          {
            adapter: :groq,
            model: "llama-3.1-8b-instant",
            url: "https://api.groq.com/openai/v1/chat/completions"
          }
        else
          # Default to Ollama for unknown adapters
          {
            adapter: :ollama,
            model: "deepseek-r1:8b",
            url: "http://localhost:11434"
          }
        end
      end

      private

      # Recursively symbolize hash keys
      def symbolize_keys(hash)
        return hash unless hash.is_a?(Hash)

        hash.transform_keys do |key|
          key.to_sym
        rescue StandardError
          key
        end
      end
    end
  end
end
