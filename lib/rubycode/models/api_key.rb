# frozen_string_literal: true

require "openssl"
require "base64"

module RubyCode
  module Models
    # Manages encrypted API keys for LLM providers
    class ApiKey < Base
      class << self
        def table_name
          :api_keys
        end

        # Save an API key for a specific adapter
        # @param adapter [Symbol] The adapter name (:ollama, :groq, etc.)
        # @param api_key [String] The plaintext API key
        def save_key(adapter:, api_key:)
          encrypted_data = encrypt(api_key)
          existing = dataset.where(adapter: adapter.to_s).first

          if existing
            update_existing_key(adapter, encrypted_data)
          else
            insert_new_key(adapter, encrypted_data)
          end
        end

        def update_existing_key(adapter, encrypted_data)
          dataset.where(adapter: adapter.to_s).update(
            encrypted_key: encrypted_data[:encrypted],
            iv: encrypted_data[:iv],
            updated_at: Time.now
          )
        end

        def insert_new_key(adapter, encrypted_data)
          dataset.insert(
            adapter: adapter.to_s,
            encrypted_key: encrypted_data[:encrypted],
            iv: encrypted_data[:iv]
          )
        end

        # Retrieve and decrypt an API key for a specific adapter
        # @param adapter [Symbol] The adapter name
        # @return [String, nil] The decrypted API key or nil if not found
        def get_key(adapter:)
          row = dataset.where(adapter: adapter.to_s).first
          return nil unless row

          decrypt(
            encrypted: row[:encrypted_key],
            init_vector: row[:iv]
          )
        end

        # Delete an API key for a specific adapter
        # @param adapter [Symbol] The adapter name
        def delete_key(adapter:)
          dataset.where(adapter: adapter.to_s).delete
        end

        # Check if an API key exists for a specific adapter
        # @param adapter [Symbol] The adapter name
        # @return [Boolean]
        def key_exists?(adapter:)
          dataset.where(adapter: adapter.to_s).any?
        end

        private

        # Encrypt a plaintext API key
        # @param plaintext [String] The API key to encrypt
        # @return [Hash] Contains :encrypted and :iv
        def encrypt(plaintext)
          cipher = OpenSSL::Cipher.new("AES-256-CBC")
          cipher.encrypt
          cipher.key = encryption_key
          iv = cipher.random_iv

          encrypted = cipher.update(plaintext) + cipher.final

          {
            encrypted: Base64.strict_encode64(encrypted),
            iv: Base64.strict_encode64(iv)
          }
        end

        # Decrypt an encrypted API key
        # @param encrypted [String] Base64-encoded encrypted data
        # @param init_vector [String] Base64-encoded initialization vector
        # @return [String] The decrypted API key
        def decrypt(encrypted:, init_vector:)
          cipher = OpenSSL::Cipher.new("AES-256-CBC")
          cipher.decrypt
          cipher.key = encryption_key
          cipher.iv = Base64.strict_decode64(init_vector)

          cipher.update(Base64.strict_decode64(encrypted)) + cipher.final
        end

        # Generate a consistent encryption key based on user's environment
        # This creates a per-user encryption key
        # @return [String] 32-byte encryption key
        def encryption_key
          # Use a combination of home directory and a salt to generate a consistent key
          # This provides per-user encryption without requiring password entry
          salt = "rubycode_api_key_encryption_v1"
          key_base = "#{Dir.home}#{salt}"

          # Use SHA-256 to generate a 32-byte key
          OpenSSL::Digest::SHA256.digest(key_base)
        end
      end
    end
  end
end
