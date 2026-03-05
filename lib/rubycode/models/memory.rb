# frozen_string_literal: true

require "sqlite3"
require "fileutils"

module RubyCode
  # Manages conversation memory using SQLite for persistence
  class Memory
    attr_reader :db_path

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
      @db.execute("SELECT role, content FROM messages ORDER BY id ASC").map do |row|
        Message.new(role: row[0], content: row[1])
      end
    end

    def to_llm_format
      messages.map(&:to_h)
    end

    def clear
      @db.execute("DELETE FROM messages")
    end

    def last_user_message
      row = @db.get_first_row("SELECT role, content FROM messages WHERE role = 'user' ORDER BY id DESC LIMIT 1")
      return nil unless row

      Message.new(role: row[0], content: row[1])
    end

    def last_assistant_message
      row = @db.get_first_row("SELECT role, content FROM messages WHERE role = 'assistant' ORDER BY id DESC LIMIT 1")
      return nil unless row

      Message.new(role: row[0], content: row[1])
    end

    def close
      @db&.close
    end

    private

    def default_db_path
      dir = File.join(Dir.home, ".rubycode")
      FileUtils.mkdir_p(dir)
      File.join(dir, "memory.db")
    end

    def setup_database
      @db = SQLite3::Database.new(@db_path)
      create_tables
    end

    def create_tables
      @db.execute <<-SQL
        CREATE TABLE IF NOT EXISTS messages (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          role TEXT NOT NULL,
          content TEXT NOT NULL,
          created_at DATETIME DEFAULT CURRENT_TIMESTAMP
        )
      SQL
    end

    def insert_message(role, content)
      @db.execute("INSERT INTO messages (role, content) VALUES (?, ?)", [role, content])
    end
  end
end
