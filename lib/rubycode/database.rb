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
      end

      def create_messages_table
        @db.create_table?(:messages) do
          primary_key :id
          String :role, null: false
          String :content, null: false, text: true
          DateTime :created_at, default: Sequel::CURRENT_TIMESTAMP
        end
      end
    end
  end
end
