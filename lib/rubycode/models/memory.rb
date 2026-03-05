# frozen_string_literal: true

require "sequel"
require "fileutils"

module RubyCode
  # Manages conversation memory using Sequel ORM with SQLite backend
  class Memory
    attr_reader :db_path, :db

    def initialize(db_path: nil)
      @db_path = db_path || default_db_path
      setup_database
    end

    # Accept either Message objects or keyword arguments for backwards compatibility
    def add_message(message = nil, role: nil, content: nil)
      if message.is_a?(Message)
        insert_message(message.role, message.content)
      elsif role && content
        insert_message(role, content)
      else
        raise ArgumentError, "Must provide either a Message object or role: and content: keyword arguments"
      end
    end

    def messages
      @db[:messages].order(:id).map do |row|
        Message.new(role: row[:role], content: row[:content])
      end
    end

    def to_llm_format
      messages.map(&:to_h)
    end

    def clear
      @db[:messages].delete
    end

    def last_user_message
      row = @db[:messages].where(role: "user").order(Sequel.desc(:id)).first
      return nil unless row

      Message.new(role: row[:role], content: row[:content])
    end

    def last_assistant_message
      row = @db[:messages].where(role: "assistant").order(Sequel.desc(:id)).first
      return nil unless row

      Message.new(role: row[:role], content: row[:content])
    end

    def close
      @db&.disconnect
    end

    private

    def default_db_path
      dir = File.join(Dir.home, ".rubycode")
      FileUtils.mkdir_p(dir)
      File.join(dir, "memory.db")
    end

    def setup_database
      @db = Sequel.sqlite(@db_path)
      create_tables
    end

    def create_tables
      @db.create_table? :messages do
        primary_key :id
        String :role, null: false
        String :content, null: false, text: true
        DateTime :created_at, default: Sequel::CURRENT_TIMESTAMP
      end
    end

    def insert_message(role, content)
      @db[:messages].insert(role: role, content: content)
    end
  end
end
