# frozen_string_literal: true

require "test_helper"

class TestRubycode < Minitest::Test
  def test_that_it_has_a_version_number
    refute_nil ::Rubycode::VERSION
  end

  def test_configuration_has_default_values
    config = Rubycode::Configuration.new
    assert_equal :ollama, config.adapter
    assert_equal "http://localhost:11434", config.url
    assert_equal "deepseek-v3.1:671b-cloud", config.model
    refute config.debug
  end

  def test_client_can_be_instantiated
    client = Rubycode::Client.new
    refute_nil client
    refute_nil client.history
  end

  def test_tools_are_available
    assert_equal 4, Rubycode::Tools::TOOLS.length
    assert_includes Rubycode::Tools::TOOLS, Rubycode::Tools::Bash
    assert_includes Rubycode::Tools::TOOLS, Rubycode::Tools::Read
    assert_includes Rubycode::Tools::TOOLS, Rubycode::Tools::Search
    assert_includes Rubycode::Tools::TOOLS, Rubycode::Tools::Done
  end

  def test_tool_definitions_are_valid
    Rubycode::Tools::TOOLS.each do |tool_class|
      definition = tool_class.definition
      assert_equal "function", definition[:type]
      refute_nil definition[:function][:name]
      refute_nil definition[:function][:description]
      refute_nil definition[:function][:parameters]
    end
  end
end
