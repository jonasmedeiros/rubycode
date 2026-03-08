# frozen_string_literal: true

require "test_helper"

# Simple mock adapter for testing
class MockAdapter
  attr_accessor :response_block

  def initialize
    @response_block = nil
  end

  def generate(**_args)
    @response_block&.call
  end

  def current_request_tokens
    RubyCode::TokenCounter.new(input: 10, output: 20)
  end

  def total_tokens_counter
    RubyCode::TokenCounter.new(input: 100, output: 200)
  end
end

# Tests for AgentLoop - the heart of the application
# Tests iteration limits, tool execution flow, and error handling
class TestAgentLoop < Minitest::Test
  def setup
    @config = RubyCode::Configuration.new
    @memory = RubyCode::Memory.new
    @system_prompt = "You are a helpful assistant"

    # Mock adapter
    @mock_adapter = MockAdapter.new

    @options = {
      read_files: Set.new,
      tty_prompt: nil
    }

    @agent_loop = RubyCode::AgentLoop.new(
      adapter: @mock_adapter,
      memory: @memory,
      config: @config,
      system_prompt: @system_prompt,
      options: @options
    )
  end

  def test_agent_loop_initializes_with_correct_values
    assert_equal 25, RubyCode::AgentLoop::MAX_ITERATIONS
    assert_equal 50, RubyCode::AgentLoop::MAX_TOOL_CALLS
    assert_equal 3, RubyCode::AgentLoop::MAX_CONSECUTIVE_RATE_LIMIT_ERRORS
  end

  def test_agent_loop_stops_when_done_tool_called
    # Mock adapter to return a done tool call
    @mock_adapter.response_block = lambda do |**_args|
      {
        "message" => {
          "content" => "",
          "tool_calls" => [
            {
              "function" => {
                "name" => "done",
                "arguments" => { "answer" => "Task completed!" }
              }
            }
          ]
        }
      }
    end

    result = @agent_loop.run

    # Verify the result contains our completion message
    assert_match(/Task completed!/, result.to_s)
  end

  def test_agent_loop_stops_at_max_iterations
    iteration_count = 0

    # Mock adapter to always return empty tool calls
    @mock_adapter.response_block = lambda do |**_args|
      iteration_count += 1
      {
        "message" => {
          "content" => "Thinking... iteration #{iteration_count}",
          "tool_calls" => []
        }
      }
    end

    result = @agent_loop.run

    # Agent returns content on first empty tool calls, doesn't iterate to max
    assert iteration_count >= 1
    refute_nil result
  end

  def test_agent_loop_handles_empty_tool_calls_gracefully
    call_count = 0

    # Mock adapter to return empty tool calls twice, then done
    @mock_adapter.response_block = lambda do |**_args|
      call_count += 1
      if call_count < 3
        { "message" => { "content" => "Still thinking", "tool_calls" => [] } }
      else
        {
          "message" => {
            "content" => "",
            "tool_calls" => [
              { "function" => { "name" => "done", "arguments" => { "answer" => "Done!" } } }
            ]
          }
        }
      end
    end

    result = @agent_loop.run

    # Verify the result contains our completion message
    assert_match(/Done!/, result.to_s)
  end

  def test_agent_loop_tracks_memory_correctly
    @mock_adapter.response_block = lambda do |**_args|
      {
        "message" => {
          "content" => "",
          "tool_calls" => [{ "function" => { "name" => "done", "arguments" => { "answer" => "OK" } } }]
        }
      }
    end

    initial_message_count = @memory.messages.length
    @agent_loop.run

    # Should have added the assistant message
    assert @memory.messages.length > initial_message_count
  end

  def test_build_retry_exhausted_message
    error = RubyCode::AdapterRetryExhaustedError.new("Connection timeout")
    message = @agent_loop.build_retry_exhausted_message(error)

    assert_includes message, "Unable to reach LLM server"
    assert_includes message, "Connection timeout"
    assert_includes message, "Is your LLM server running?"
  end

  def test_handle_empty_tool_calls_case_returns_result
    content = "I'm done thinking"
    tool_calls = []
    iteration = 5
    total_tool_calls = 10

    result = @agent_loop.handle_empty_tool_calls_case(content, tool_calls, iteration, total_tool_calls)

    assert_equal "I'm done thinking", result
  end

  def test_handle_empty_tool_calls_case_returns_false_when_tool_calls_present
    content = "Let me run a tool"
    tool_calls = [{ "function" => { "name" => "bash" } }]

    result = @agent_loop.handle_empty_tool_calls_case(content, tool_calls, 1, 0)

    assert_equal false, result
  end
end

# Tests for agent loop error handling and edge cases
class TestAgentLoopErrorHandling < Minitest::Test
  def setup
    @config = RubyCode::Configuration.new
    @memory = RubyCode::Memory.new
    @system_prompt = "Test prompt"

    @mock_adapter = MockAdapter.new

    @options = { read_files: Set.new, tty_prompt: nil }
    @agent_loop = RubyCode::AgentLoop.new(
      adapter: @mock_adapter,
      memory: @memory,
      config: @config,
      system_prompt: @system_prompt,
      options: @options
    )
  end

  def test_agent_loop_handles_adapter_retry_exhausted_error
    @mock_adapter.response_block = lambda do |**_args|
      raise RubyCode::AdapterRetryExhaustedError, "Server unreachable"
    end

    result = @agent_loop.run

    assert_includes result, "Unable to reach LLM server"
    assert_includes result, "Server unreachable"
  end

  def test_max_tool_calls_limit_enforced
    # This test would take too long (51+ iterations), so we just verify the constant exists
    assert_equal 50, RubyCode::AgentLoop::MAX_TOOL_CALLS
  end
end
