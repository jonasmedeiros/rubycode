# frozen_string_literal: true

require_relative "test_helper"
require "tempfile"

class TestConfiguration < Minitest::Test
  def test_configuration_defaults
    config = RubyCode::Configuration.new

    assert_equal :ollama, config.adapter
    assert_equal "https://api.ollama.com", config.url
    assert_equal "qwen3-coder:480b-cloud", config.model
    assert_equal Dir.pwd, config.root_path
    assert_equal 120, config.http_read_timeout
    assert_equal 10, config.http_open_timeout
    assert_equal 3, config.max_retries
    assert_equal 2.0, config.retry_base_delay
    assert_equal 1.5, config.adapter_request_delay
    assert_equal 10, config.memory_window
    assert_equal true, config.prune_tool_results
  end

  def test_configuration_setter_methods
    config = RubyCode::Configuration.new

    config.adapter = :gemini
    config.url = "https://test.com"
    config.model = "test-model"
    config.http_read_timeout = 60
    config.memory_window = 20

    assert_equal :gemini, config.adapter
    assert_equal "https://test.com", config.url
    assert_equal "test-model", config.model
    assert_equal 60, config.http_read_timeout
    assert_equal 20, config.memory_window
  end

  def test_load_from_hash
    config = RubyCode::Configuration.new
    config.load_from_hash(adapter: :openai, model: "gpt-4", url: "https://openai.com", root_path: "/tmp")

    assert_equal :openai, config.adapter
    assert_equal "gpt-4", config.model
    assert_equal "https://openai.com", config.url
    assert_equal "/tmp", config.root_path
  end
end

class TestConfigManager < Minitest::Test
  def setup
    # Backup existing config if it exists
    @backup_path = nil
    if File.exist?(RubyCode::ConfigManager::CONFIG_FILE)
      @backup_path = "#{RubyCode::ConfigManager::CONFIG_FILE}.backup"
      FileUtils.cp(RubyCode::ConfigManager::CONFIG_FILE, @backup_path)
    end

    # Clean up config file for testing
    File.delete(RubyCode::ConfigManager::CONFIG_FILE) if File.exist?(RubyCode::ConfigManager::CONFIG_FILE)
  end

  def teardown
    # Clean up test config
    File.delete(RubyCode::ConfigManager::CONFIG_FILE) if File.exist?(RubyCode::ConfigManager::CONFIG_FILE)

    # Restore backup if it exists
    if @backup_path && File.exist?(@backup_path)
      FileUtils.mv(@backup_path, RubyCode::ConfigManager::CONFIG_FILE)
    end
  end

  def test_save_and_load
    config = {
      adapter: :gemini,
      model: "gemini-2.0-flash-exp",
      url: "https://test.com"
    }

    RubyCode::ConfigManager.save(config)
    loaded = RubyCode::ConfigManager.load

    assert_equal :gemini, loaded[:adapter]
    assert_equal "gemini-2.0-flash-exp", loaded[:model]
    assert_equal "https://test.com", loaded[:url]
  end

  def test_exists
    refute RubyCode::ConfigManager.exists?

    RubyCode::ConfigManager.save({ adapter: :ollama })

    assert RubyCode::ConfigManager.exists?
  end

  def test_defaults_for_adapter
    defaults = RubyCode::ConfigManager.defaults_for_adapter(:groq)

    assert_equal :groq, defaults[:adapter]
    assert_equal "llama-3.1-8b-instant", defaults[:model]
    assert_equal "https://api.groq.com/openai/v1/chat/completions", defaults[:url]
  end
end

class TestTokenCounter < Minitest::Test
  def test_initialization
    counter = RubyCode::TokenCounter.new(input: 100, output: 50, cached: 10, thinking: 5)

    assert_equal 100, counter.input
    assert_equal 50, counter.output
    assert_equal 10, counter.cached
    assert_equal 5, counter.thinking
  end

  def test_defaults_to_zero
    counter = RubyCode::TokenCounter.new

    assert_equal 0, counter.input
    assert_equal 0, counter.output
    assert_equal 0, counter.cached
    assert_equal 0, counter.thinking
  end

  def test_addition
    counter1 = RubyCode::TokenCounter.new(input: 100, output: 50)
    counter2 = RubyCode::TokenCounter.new(input: 200, output: 75)

    result = counter1 + counter2

    assert_equal 300, result.input
    assert_equal 125, result.output
  end
end

class TestPricing < Minitest::Test
  def test_calculate_cost_ollama
    tokens = RubyCode::TokenCounter.new(input: 1_000_000, output: 500_000)
    cost = RubyCode::Pricing.calculate_cost(adapter: :ollama, model: "qwen3-coder:480b-cloud", tokens: tokens)

    # Ollama cloud pricing
    assert cost.is_a?(Numeric)
    assert cost >= 0
  end

  def test_calculate_cost_gemini
    tokens = RubyCode::TokenCounter.new(input: 1_000_000, output: 1_000_000)
    cost = RubyCode::Pricing.calculate_cost(adapter: :gemini, model: "gemini-2.0-flash-exp", tokens: tokens)

    assert cost.is_a?(Numeric)
    assert cost >= 0
  end

  def test_calculate_cost_with_cached_tokens
    tokens = RubyCode::TokenCounter.new(input: 1_000_000, output: 1_000_000, cached: 500_000)
    cost = RubyCode::Pricing.calculate_cost(adapter: :gemini, model: "gemini-2.0-flash-exp", tokens: tokens)

    # Cost should account for cached tokens
    assert cost.is_a?(Numeric)
    assert cost >= 0
  end

  def test_format_cost_cents
    formatted = RubyCode::Pricing.format_cost(0.0001)
    assert_includes formatted, "¢"
  end

  def test_format_cost_dollars
    formatted = RubyCode::Pricing.format_cost(1.5)
    assert formatted.start_with?("$1.")
  end
end
