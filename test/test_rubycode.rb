# frozen_string_literal: true

require "test_helper"

class TestRubycode < Minitest::Test
  def test_that_it_has_a_version_number
    refute_nil ::RubyCode::VERSION
  end

  def test_configuration_has_default_values
    config = RubyCode::Configuration.new
    assert_equal :ollama, config.adapter
    assert_equal "http://localhost:11434", config.url
    assert_equal "deepseek-v3.1:671b-cloud", config.model
    refute config.debug
  end

  def test_client_can_be_instantiated
    client = RubyCode::Client.new
    refute_nil client
    refute_nil client.history
  end

  def test_tools_are_available
    assert_equal 4, RubyCode::Tools::TOOLS.length
    assert_includes RubyCode::Tools::TOOLS, RubyCode::Tools::Bash
    assert_includes RubyCode::Tools::TOOLS, RubyCode::Tools::Read
    assert_includes RubyCode::Tools::TOOLS, RubyCode::Tools::Search
    assert_includes RubyCode::Tools::TOOLS, RubyCode::Tools::Done
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
