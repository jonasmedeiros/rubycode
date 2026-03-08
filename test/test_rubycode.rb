# frozen_string_literal: true

require "test_helper"

class TestRubycode < Minitest::Test
  def test_that_it_has_a_version_number
    refute_nil ::RubyCode::VERSION
  end

  def test_configuration_has_default_values
    config = RubyCode::Configuration.new
    assert_equal :ollama, config.adapter
    assert_equal "https://api.ollama.com", config.url
    assert_equal "qwen3-coder:480b-cloud", config.model
  end

  def test_client_can_be_instantiated
    # Provide API key for test
    ENV["OLLAMA_API_KEY"] = "test-key"
    client = RubyCode::Client.new
    refute_nil client
    refute_nil client.memory
    ENV.delete("OLLAMA_API_KEY")
  end

  def test_tools_are_available
    assert_equal 9, RubyCode::Tools::TOOLS.length
    assert_includes RubyCode::Tools::TOOLS, RubyCode::Tools::Bash
    assert_includes RubyCode::Tools::TOOLS, RubyCode::Tools::Read
    assert_includes RubyCode::Tools::TOOLS, RubyCode::Tools::Explore
    assert_includes RubyCode::Tools::TOOLS, RubyCode::Tools::Search
    assert_includes RubyCode::Tools::TOOLS, RubyCode::Tools::Done
    assert_includes RubyCode::Tools::TOOLS, RubyCode::Tools::WebSearch
    assert_includes RubyCode::Tools::TOOLS, RubyCode::Tools::Fetch
  end

  def test_tool_definitions_are_valid
    RubyCode::Tools::TOOLS.each do |tool_class|
      definition = tool_class.definition
      assert_equal "function", definition[:type]
      refute_nil definition[:function][:name]
      refute_nil definition[:function][:description]
      refute_nil definition[:function][:parameters]
    end
  end
end
