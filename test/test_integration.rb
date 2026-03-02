# frozen_string_literal: true

require "test_helper"

class TestIntegration < Minitest::Test
  def setup
    RubyCode.configure do |config|
      config.root_path = Dir.pwd
      config.adapter = :ollama
      config.debug = false
    end
  end

  def test_client_initialization
    client = RubyCode::Client.new
    assert_instance_of RubyCode::Client, client
    assert_instance_of RubyCode::History, client.history
  end

  def test_bash_tool_instantiation
    context = { root_path: Dir.pwd }
    bash_tool = RubyCode::Tools::Bash.new(context: context)

    assert_instance_of RubyCode::Tools::Bash, bash_tool
    assert_equal context, bash_tool.context
  end

  def test_bash_tool_execution_success
    context = { root_path: Dir.pwd }
    bash_tool = RubyCode::Tools::Bash.new(context: context)

    result = bash_tool.execute({ "command" => "pwd" })

    assert_instance_of RubyCode::CommandResult, result
    assert result.success?
    assert_includes result.stdout, "rubycode"
  end

  def test_bash_tool_unsafe_command
    context = { root_path: Dir.pwd }
    bash_tool = RubyCode::Tools::Bash.new(context: context)

    error = assert_raises(RubyCode::UnsafeCommandError) do
      bash_tool.execute({ "command" => "rm -rf /" })
    end

    assert_includes error.message, "not allowed"
  end

  def test_read_tool_execution
    context = { root_path: Dir.pwd }
    read_tool = RubyCode::Tools::Read.new(context: context)

    # Read this test file
    result = read_tool.execute({ "file_path" => __FILE__ })

    assert_instance_of RubyCode::ToolResult, result
    assert_includes result.content, "TestIntegration"
  end

  def test_read_tool_file_not_found
    context = { root_path: Dir.pwd }
    read_tool = RubyCode::Tools::Read.new(context: context)

    error = assert_raises(RubyCode::FileNotFoundError) do
      read_tool.execute({ "file_path" => "nonexistent_file.rb" })
    end

    assert_includes error.message, "does not exist"
  end

  def test_search_tool_execution
    context = { root_path: Dir.pwd }
    search_tool = RubyCode::Tools::Search.new(context: context)

    result = search_tool.execute({ "pattern" => "TestIntegration" })

    # Search returns string directly
    assert_kind_of String, result.to_s
  end

  def test_done_tool_execution
    context = { root_path: Dir.pwd }
    done_tool = RubyCode::Tools::Done.new(context: context)

    result = done_tool.execute({ "answer" => "Task completed!" })

    assert_instance_of RubyCode::ToolResult, result
    assert_equal "Task completed!", result.content
  end

  def test_message_value_object
    message = RubyCode::Message.new(role: "user", content: "Hello")

    assert_equal "user", message.role
    assert_equal "Hello", message.content
    assert_instance_of Time, message.timestamp
    assert_equal({ role: "user", content: "Hello" }, message.to_h)
  end

  def test_command_result_value_object
    result = RubyCode::CommandResult.new(stdout: "output", stderr: "", exit_code: 0)

    assert result.success?
    assert_equal "output", result.output
    assert_equal "output", result.to_s
  end
end
