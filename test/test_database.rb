# frozen_string_literal: true

require "test_helper"

class TestDatabase < Minitest::Test
  def setup
    # Ensure we start with a clean database connection
    RubyCode::Database.disconnect
  end

  def teardown
    # Clean up after tests
    RubyCode::Database.disconnect
  end

  def test_connect_creates_database_connection
    db = RubyCode::Database.connect
    assert_instance_of Sequel::SQLite::Database, db
  end

  def test_connect_accepts_custom_db_path
    custom_path = File.join(Dir.tmpdir, "test_custom.db")
    db = RubyCode::Database.connect(db_path: custom_path)
    assert_instance_of Sequel::SQLite::Database, db
  ensure
    FileUtils.rm_f(custom_path)
  end

  def test_connection_returns_existing_or_creates_new
    # First call creates connection
    db1 = RubyCode::Database.connection
    assert_instance_of Sequel::SQLite::Database, db1

    # Second call returns same connection
    db2 = RubyCode::Database.connection
    assert_equal db1, db2
  end

  def test_disconnect_closes_connection
    RubyCode::Database.connect
    refute_nil RubyCode::Database.db

    RubyCode::Database.disconnect
    assert_nil RubyCode::Database.db
  end

  def test_creates_messages_table_on_connect
    db = RubyCode::Database.connect
    assert db.table_exists?(:messages)
  end

  def test_messages_table_has_correct_schema
    db = RubyCode::Database.connect
    schema = db.schema(:messages)
    column_names = schema.map { |col| col[0] }

    assert_includes column_names, :id
    assert_includes column_names, :role
    assert_includes column_names, :content
    assert_includes column_names, :created_at
  end
end
