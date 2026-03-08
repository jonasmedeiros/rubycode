# frozen_string_literal: true

require "test_helper"

class TestMemory < Minitest::Test
  def setup
    @memory = RubyCode::Memory.new
    @memory.clear
  end

  def teardown
    @memory.clear
  end

  def test_table_name_is_messages
    assert_equal :messages, RubyCode::Memory.table_name
  end

  def test_add_message_with_keyword_arguments
    @memory.add_message(role: "user", content: "Hello")
    messages = @memory.messages
    assert_equal 1, messages.count
    assert_equal "user", messages.first.role
    assert_equal "Hello", messages.first.content
  end

  def test_add_message_with_message_object
    message = RubyCode::Message.new(role: "assistant", content: "Hi there")
    @memory.add_message(message)

    messages = @memory.messages
    assert_equal 1, messages.count
    assert_equal "assistant", messages.first.role
    assert_equal "Hi there", messages.first.content
  end

  def test_add_message_raises_error_without_arguments
    error = assert_raises(ArgumentError) do
      @memory.add_message
    end
    assert_match(/Must provide either a Message object or role: and content:/, error.message)
  end

  def test_messages_returns_array_of_message_objects
    @memory.add_message(role: "user", content: "First")
    @memory.add_message(role: "assistant", content: "Second")

    messages = @memory.messages
    assert_equal 2, messages.count
    assert_instance_of RubyCode::Message, messages.first
    assert_instance_of RubyCode::Message, messages.last
  end

  def test_messages_ordered_by_id
    @memory.add_message(role: "user", content: "First")
    @memory.add_message(role: "assistant", content: "Second")
    @memory.add_message(role: "user", content: "Third")

    messages = @memory.messages
    assert_equal "First", messages[0].content
    assert_equal "Second", messages[1].content
    assert_equal "Third", messages[2].content
  end

  def test_to_llm_format_returns_hash_array
    @memory.add_message(role: "user", content: "Hello")
    @memory.add_message(role: "assistant", content: "Hi")

    llm_format = @memory.to_llm_format
    assert_instance_of Array, llm_format
    assert_equal 2, llm_format.count
    assert_instance_of Hash, llm_format.first
    assert_equal({ role: "user", content: "Hello" }, llm_format.first)
  end

  def test_clear_removes_all_messages
    @memory.add_message(role: "user", content: "First")
    @memory.add_message(role: "assistant", content: "Second")
    assert_equal 2, @memory.messages.count

    @memory.clear
    assert_equal 0, @memory.messages.count
  end

  def test_last_user_message_returns_most_recent_user_message
    @memory.add_message(role: "user", content: "First user")
    @memory.add_message(role: "assistant", content: "Response")
    @memory.add_message(role: "user", content: "Second user")

    last_user = @memory.last_user_message
    assert_equal "user", last_user.role
    assert_equal "Second user", last_user.content
  end

  def test_last_user_message_returns_nil_when_no_user_messages
    @memory.add_message(role: "assistant", content: "Only assistant")
    assert_nil @memory.last_user_message
  end

  def test_last_assistant_message_returns_most_recent_assistant_message
    @memory.add_message(role: "assistant", content: "First assistant")
    @memory.add_message(role: "user", content: "User message")
    @memory.add_message(role: "assistant", content: "Second assistant")

    last_assistant = @memory.last_assistant_message
    assert_equal "assistant", last_assistant.role
    assert_equal "Second assistant", last_assistant.content
  end

  def test_last_assistant_message_returns_nil_when_no_assistant_messages
    @memory.add_message(role: "user", content: "Only user")
    assert_nil @memory.last_assistant_message
  end

  def test_class_methods_inherited_from_base
    @memory.add_message(role: "user", content: "Test")
    assert_equal 1, RubyCode::Memory.count
    assert_instance_of Sequel::SQLite::Dataset, RubyCode::Memory.dataset
  end

  def test_latest_and_where_chaining
    @memory.add_message(role: "user", content: "First user")
    @memory.add_message(role: "assistant", content: "Assistant")
    @memory.add_message(role: "user", content: "Second user")

    latest_user = RubyCode::Memory.latest.where(role: "user").first
    assert_equal "Second user", latest_user[:content]
  end

  def test_add_message_with_tool_calls
    tool_calls = [{ "function" => { "name" => "bash", "arguments" => { "command" => "ls" } } }]
    @memory.add_message(role: "assistant", content: "Running command", tool_calls: tool_calls)

    messages = @memory.messages
    assert_equal 1, messages.count
    assert_equal tool_calls, messages.first.tool_calls
  end

  def test_add_message_object_with_tool_calls
    tool_calls = [{ "function" => { "name" => "read", "arguments" => { "file_path" => "test.rb" } } }]
    message = RubyCode::Message.new(role: "assistant", content: "Reading file", tool_calls: tool_calls)
    @memory.add_message(message)

    messages = @memory.messages
    assert_equal tool_calls, messages.first.tool_calls
  end

  def test_to_llm_format_includes_tool_calls
    tool_calls = [{ "function" => { "name" => "bash", "arguments" => { "command" => "pwd" } } }]
    @memory.add_message(role: "assistant", content: "Executing", tool_calls: tool_calls)

    llm_format = @memory.to_llm_format
    assert_equal tool_calls, llm_format.first[:tool_calls]
  end

  def test_messages_without_tool_calls_still_work
    @memory.add_message(role: "user", content: "Hello")

    messages = @memory.messages
    assert_nil messages.first.tool_calls

    llm_format = @memory.to_llm_format
    assert_equal({ role: "user", content: "Hello" }, llm_format.first)
  end

  def test_tool_calls_empty_array_serializes_as_nil
    @memory.add_message(role: "assistant", content: "No tools", tool_calls: [])

    messages = @memory.messages
    assert_nil messages.first.tool_calls
  end

  def test_last_user_message_includes_tool_calls
    tool_calls = [{ "function" => { "name" => "search", "arguments" => { "query" => "test" } } }]
    @memory.add_message(role: "user", content: "First")
    @memory.add_message(role: "user", content: "Second", tool_calls: tool_calls)

    last_user = @memory.last_user_message
    assert_equal tool_calls, last_user.tool_calls
  end

  def test_last_assistant_message_includes_tool_calls
    tool_calls = [{ "function" => { "name" => "done", "arguments" => { "result" => "complete" } } }]
    @memory.add_message(role: "assistant", content: "First")
    @memory.add_message(role: "assistant", content: "Second", tool_calls: tool_calls)

    last_assistant = @memory.last_assistant_message
    assert_equal tool_calls, last_assistant.tool_calls
  end

  def test_to_llm_format_with_window_returns_all_when_count_less_than_window
    5.times { |i| @memory.add_message(role: "user", content: "Message #{i}") }

    llm_format = @memory.to_llm_format(window_size: 10)
    assert_equal 5, llm_format.count
  end

  def test_to_llm_format_with_window_keeps_first_and_last_n
    15.times { |i| @memory.add_message(role: "user", content: "Message #{i}") }

    llm_format = @memory.to_llm_format(window_size: 5)
    # Should have: first + last 5 = 6 messages (deduplicated if first is in last 5)
    assert llm_format.count <= 6
    assert_equal "Message 0", llm_format.first[:content] # First message
    assert_equal "Message 14", llm_format.last[:content] # Last message
  end

  def test_to_llm_format_prunes_tool_results_in_middle
    @memory.add_message(role: "user", content: "Task")
    5.times do
      @memory.add_message(role: "assistant", content: "Calling tool")
      @memory.add_message(role: "user", content: "Tool 'bash' result:\noutput")
    end
    @memory.add_message(role: "user", content: "Recent message")

    llm_format = @memory.to_llm_format(window_size: 2, prune_tool_results: true)

    # Check that middle tool results are cleared
    pruned = llm_format.select { |m| m[:content] == "[Tool result cleared]" }
    assert pruned.any?, "Expected some tool results to be pruned"
  end

  def test_to_llm_format_with_pruning_disabled
    @memory.add_message(role: "user", content: "Task")
    3.times { @memory.add_message(role: "user", content: "Tool 'bash' result:\noutput") }
    @memory.add_message(role: "user", content: "Recent")

    llm_format = @memory.to_llm_format(window_size: 2, prune_tool_results: false)

    # Tool results should not be cleared
    cleared = llm_format.select { |m| m[:content] == "[Tool result cleared]" }
    assert_equal 0, cleared.count
  end

  def test_to_llm_format_deduplicates_first_message_in_window
    3.times { |i| @memory.add_message(role: "user", content: "Message #{i}") }

    llm_format = @memory.to_llm_format(window_size: 5)
    # Should have 3 messages, no duplicates
    assert_equal 3, llm_format.count
  end

  def test_to_llm_format_empty_memory
    llm_format = @memory.to_llm_format(window_size: 10)
    assert_equal 0, llm_format.count
  end
end
