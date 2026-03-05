# frozen_string_literal: true

require "test_helper"

# Test model that inherits from Base for testing
class TestModel < RubyCode::Models::Base
  class << self
    def table_name
      :messages
    end
  end
end

class TestModelsBase < Minitest::Test
  def setup
    # Ensure clean database for each test
    RubyCode::Database.connection[:messages].delete
  end

  def teardown
    RubyCode::Database.connection[:messages].delete
  end

  def test_table_name_must_be_implemented
    error = assert_raises(NotImplementedError) do
      RubyCode::Models::Base.table_name
    end
    assert_match(/Subclasses must define table_name/, error.message)
  end

  def test_dataset_returns_sequel_dataset
    dataset = TestModel.dataset
    assert_instance_of Sequel::SQLite::Dataset, dataset
  end

  def test_where_filters_records
    insert_test_messages
    result = TestModel.where(role: "user").all
    assert_equal 2, result.count
  end

  def test_order_ascending
    insert_test_messages
    result = TestModel.order(:id, :asc).all
    assert_equal "First", result.first[:content]
  end

  def test_order_descending
    insert_test_messages
    result = TestModel.order(:id, :desc).all
    assert_equal "Third", result.first[:content]
  end

  def test_latest_orders_descending
    insert_test_messages
    result = TestModel.latest.all
    assert_equal "Third", result.first[:content]
  end

  def test_oldest_orders_ascending
    insert_test_messages
    result = TestModel.oldest.all
    assert_equal "First", result.first[:content]
  end

  def test_delete_removes_all_records
    insert_test_messages
    assert_equal 3, TestModel.count

    TestModel.delete
    assert_equal 0, TestModel.count
  end

  def test_all_returns_all_records
    insert_test_messages
    result = TestModel.all
    assert_equal 3, result.count
  end

  def test_first_returns_first_record
    insert_test_messages
    result = TestModel.first
    assert_equal "First", result[:content]
  end

  def test_last_returns_last_record
    insert_test_messages
    result = TestModel.last
    assert_equal "Third", result[:content]
  end

  def test_count_returns_record_count
    assert_equal 0, TestModel.count
    insert_test_messages
    assert_equal 3, TestModel.count
  end

  def test_chaining_latest_with_where
    insert_test_messages
    result = TestModel.latest.where(role: "user").first
    assert_equal "Second", result[:content]
  end

  def test_instance_has_access_to_db_connection
    model = TestModel.new
    db = model.send(:db)
    assert_instance_of Sequel::SQLite::Database, db
  end

  private

  def insert_test_messages
    db = RubyCode::Database.connection
    db[:messages].insert(role: "user", content: "First")
    db[:messages].insert(role: "user", content: "Second")
    db[:messages].insert(role: "assistant", content: "Third")
  end
end
