# frozen_string_literal: true

require "sequel"
require "fileutils"

module RubyCode
  # Database connection manager for all models
  class Database
    class << self
      attr_accessor :db

      def connect(db_path: nil)
        path = db_path || default_db_path
        @db = Sequel.sqlite(path)
        run_migrations
        @db
      end

      def disconnect
        @db&.disconnect
        @db = nil
      end

      def connection
        @db || connect
      end

      private

      def default_db_path
        dir = File.join(Dir.home, ".rubycode")
        FileUtils.mkdir_p(dir)
        File.join(dir, "memory.db")
      end

      def run_migrations
        create_messages_table
        create_api_keys_table
      end

      def create_messages_table
        @db.create_table?(:messages) do
          primary_key :id
          String :role, null: false
          String :content, null: false, text: true
          DateTime :created_at, default: Sequel::CURRENT_TIMESTAMP
        end

        # Add tool_calls column if it doesn't exist (migration for existing databases)
        return if @db.schema(:messages).any? { |col| col[0] == :tool_calls }

        @db.alter_table(:messages) do
          add_column :tool_calls, String, text: true, null: true
        end
      end

      def create_api_keys_table
        @db.create_table?(:api_keys) do
          primary_key :id
          String :adapter, null: false, unique: true
          String :encrypted_key, null: false, text: true
          String :iv, null: false # Initialization vector for encryption
          DateTime :created_at, default: Sequel::CURRENT_TIMESTAMP
          DateTime :updated_at, default: Sequel::CURRENT_TIMESTAMP
        end
      end
    end
  end
end
