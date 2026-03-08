# frozen_string_literal: true

require "test_helper"

# Tests for Adapters::Base and all adapter implementations
# All HTTP calls are mocked - no internet required
class TestAdaptersBase < Minitest::Test
  def setup
    @config = RubyCode::Configuration.new
    @config.adapter = :ollama
    @config.model = "test-model"
    @config.url = "https://api.test.com"
    ENV["OLLAMA_API_KEY"] = "test-key"
    ENV["GEMINI_API_KEY"] = "test-key"
  end

  def teardown
    ENV.delete("OLLAMA_API_KEY")
    ENV.delete("GEMINI_API_KEY")
  end

  def test_adapter_initializes_with_zero_tokens
    adapter = RubyCode::Adapters::Ollama.new(@config)

    assert_instance_of RubyCode::TokenCounter, adapter.total_tokens_counter
    assert_equal 0, adapter.total_tokens_counter.input
    assert_equal 0, adapter.total_tokens_counter.output
  end

  def test_adapter_enforces_rate_limit_delay
    adapter = RubyCode::Adapters::Ollama.new(@config)
    @config.adapter_request_delay = 0.1

    # First request - no delay
    start_time = Time.now
    adapter.send(:enforce_rate_limit_delay)
    elapsed = Time.now - start_time
    assert elapsed < 0.05, "First request should have no delay"

    # Simulate a recent request
    adapter.instance_variable_set(:@last_request_time, Time.now)

    # Second request - should delay
    start_time = Time.now
    adapter.send(:enforce_rate_limit_delay)
    elapsed = Time.now - start_time
    assert elapsed >= 0.05, "Second request should delay at least 50ms"
  end

  def test_adapter_symbol_conversion
    adapter = RubyCode::Adapters::Ollama.new(@config)
    assert_equal :ollama, adapter.send(:adapter_symbol)

    gemini_adapter = RubyCode::Adapters::Gemini.new(@config)
    assert_equal :gemini, gemini_adapter.send(:adapter_symbol)
  end

  def test_api_key_from_database_takes_precedence
    # Save a key to database
    RubyCode::Database.connect
    RubyCode::Models::ApiKey.save_key(adapter: :ollama, api_key: "db-key-123")

    # Set environment variable
    ENV["OLLAMA_API_KEY"] = "env-key-456"

    adapter = RubyCode::Adapters::Ollama.new(@config)
    assert_equal "db-key-123", adapter.send(:api_key)

    # Cleanup
    RubyCode::Database.connection[:api_keys].where(adapter: "ollama").delete
    ENV.delete("OLLAMA_API_KEY")
  end

  def test_api_key_falls_back_to_env_variable
    # Ensure no database key exists
    RubyCode::Database.connect
    RubyCode::Database.connection[:api_keys].where(adapter: "ollama").delete

    ENV["OLLAMA_API_KEY"] = "env-key-789"
    adapter = RubyCode::Adapters::Ollama.new(@config)
    assert_equal "env-key-789", adapter.send(:api_key)

    ENV.delete("OLLAMA_API_KEY")
  end
end

class TestAdaptersOllama < Minitest::Test
  def setup
    @config = RubyCode::Configuration.new
    @config.adapter = :ollama
    @config.model = "test-model"
    @config.url = "https://api.ollama.com"

    ENV["OLLAMA_API_KEY"] = "test-key"
    @adapter = RubyCode::Adapters::Ollama.new(@config)
  end

  def teardown
    ENV.delete("OLLAMA_API_KEY")
  end

  def test_build_payload_with_messages_only
    messages = [{ role: "user", content: "Hello" }]
    payload = @adapter.send(:build_payload, messages, nil, nil)

    assert_equal "test-model", payload[:model]
    assert_equal messages, payload[:messages]
    assert_equal false, payload[:stream]
    refute payload.key?(:system)
    refute payload.key?(:tools)
  end

  def test_build_payload_with_system_and_tools
    messages = [{ role: "user", content: "Hello" }]
    system = "You are a helpful assistant"
    tools = [{ function: { name: "test_tool" } }]

    payload = @adapter.send(:build_payload, messages, system, tools)

    assert_equal system, payload[:system]
    assert_equal tools, payload[:tools]
  end

  def test_parse_xml_tool_calls_from_content
    content = <<~XML
      Let me help you.
      <tool_call>
      {"name": "bash", "arguments": {"command": "ls -la"}}
      </tool_call>
      Done!
    XML

    body = { "message" => { "content" => content } }
    @adapter.send(:parse_tool_calls_from_content, body)

    tool_calls = body["message"]["tool_calls"]
    assert_equal 1, tool_calls.length
    assert_equal "bash", tool_calls[0]["function"]["name"]
    assert_equal({ "command" => "ls -la" }, tool_calls[0]["function"]["arguments"])

    # Content should be cleaned
    clean_content = body["message"]["content"]
    refute_includes clean_content, "<tool_call>"
  end

  def test_parse_json_tool_call_from_content
    content = '{"name": "done", "arguments": {"result": "Success"}}'

    body = { "message" => { "content" => content } }
    @adapter.send(:parse_tool_calls_from_content, body)

    tool_calls = body["message"]["tool_calls"]
    assert_equal 1, tool_calls.length
    assert_equal "done", tool_calls[0]["function"]["name"]
    assert_equal({ "result" => "Success" }, tool_calls[0]["function"]["arguments"])

    # Content should be empty
    assert_equal "", body["message"]["content"]
  end

  def test_extract_tokens_from_ollama_response
    response = {
      "prompt_eval_count" => 100,
      "eval_count" => 50
    }

    tokens = @adapter.send(:extract_tokens, response)

    assert_equal 100, tokens.input
    assert_equal 50, tokens.output
  end

  def test_generate_makes_http_request
    # Mock the send_request_with_retry method
    mock_response = {
      "message" => { "content" => "Hello!", "tool_calls" => [] },
      "prompt_eval_count" => 10,
      "eval_count" => 20
    }

    @adapter.define_singleton_method(:send_request_with_retry) { |_uri, _req| mock_response }

    result = @adapter.generate(
      messages: [{ role: "user", content: "Hi" }],
      system: nil,
      tools: nil
    )

    assert_equal "Hello!", result["message"]["content"]
    assert_equal 10, @adapter.current_request_tokens.input
    assert_equal 20, @adapter.current_request_tokens.output
  end
end

class TestAdaptersGemini < Minitest::Test
  def setup
    @config = RubyCode::Configuration.new
    @config.adapter = :gemini
    @config.model = "gemini-2.5-flash"

    ENV["GEMINI_API_KEY"] = "test-key"
    @adapter = RubyCode::Adapters::Gemini.new(@config)
  end

  def teardown
    ENV.delete("GEMINI_API_KEY")
  end

  def test_build_payload_converts_messages_to_gemini_format
    messages = [{ role: "user", content: "Hello" }, { role: "assistant", content: "Hi there!" }]
    payload = @adapter.send(:build_payload, messages, nil, nil)

    assert_equal 2, payload[:contents].length
    assert_equal "user", payload[:contents][0][:role]
    assert_equal "model", payload[:contents][1][:role]
    assert_equal "Hello", payload[:contents][0][:parts][0][:text]
  end

  def test_build_payload_includes_system_instruction
    messages = [{ role: "user", content: "Hello" }]
    system = "Be helpful"

    payload = @adapter.send(:build_payload, messages, system, nil)

    assert_equal "Be helpful", payload[:systemInstruction][:parts][0][:text]
  end

  def test_convert_tools_to_gemini_format
    tools = [
      {
        function: {
          name: "bash",
          description: "Execute bash command",
          parameters: { type: "object", properties: {} }
        }
      }
    ]

    gemini_tools = @adapter.send(:convert_tools_to_gemini_format, tools)

    assert_equal 1, gemini_tools[0][:functionDeclarations].length
    assert_equal "bash", gemini_tools[0][:functionDeclarations][0][:name]
    assert_equal "Execute bash command", gemini_tools[0][:functionDeclarations][0][:description]
  end

  def test_convert_response_extracts_text_content
    gemini_response = {
      "candidates" => [
        {
          "content" => {
            "parts" => [
              { "text" => "Hello " },
              { "text" => "world!" }
            ],
            "role" => "model"
          }
        }
      ]
    }

    result = @adapter.send(:convert_response, gemini_response)

    assert_equal "Hello \nworld!", result["message"]["content"]
    assert_equal [], result["message"]["tool_calls"]
  end

  def test_convert_response_extracts_function_calls
    gemini_response = build_gemini_function_call_response

    result = @adapter.send(:convert_response, gemini_response)

    assert_equal 1, result["message"]["tool_calls"].length
    assert_equal "bash", result["message"]["tool_calls"][0]["function"]["name"]
    assert_equal({ "command" => "pwd" }, result["message"]["tool_calls"][0]["function"]["arguments"])
  end

  private

  def build_gemini_function_call_response
    {
      "candidates" => [
        {
          "content" => {
            "parts" => [{ "functionCall" => { "name" => "bash", "args" => { "command" => "pwd" } } }],
            "role" => "model"
          }
        }
      ]
    }
  end

  def test_extract_tokens_from_gemini_response
    response = {
      "usageMetadata" => {
        "promptTokenCount" => 100,
        "candidatesTokenCount" => 30,
        "thoughtsTokenCount" => 20
      }
    }

    tokens = @adapter.send(:extract_tokens, response)

    assert_equal 100, tokens.input
    assert_equal 50, tokens.output # 30 + 20
    assert_equal 20, tokens.thinking
  end

  def test_api_endpoint_includes_key_in_url
    # Mock api_key to return our test key
    @adapter.define_singleton_method(:api_key) { "test-key-123" }

    endpoint = @adapter.send(:api_endpoint)

    assert_includes endpoint, "gemini-2.5-flash"
    assert_includes endpoint, "key=test-key-123"
  end

  def test_sanitize_url_hides_api_key
    uri = URI("https://example.com/api?key=secret123&other=value")
    sanitized = @adapter.send(:sanitize_url, uri)

    assert_includes sanitized, "key=***"
    refute_includes sanitized, "secret123"
    assert_includes sanitized, "other=value"
  end
end

class TestAdaptersOpenAI < Minitest::Test
  def setup
    @config = RubyCode::Configuration.new
    @config.adapter = :openai
    @config.model = "gpt-4"
    @config.url = "https://api.openai.com/v1/chat/completions"

    ENV["OPENAI_API_KEY"] = "test-key"
    @adapter = RubyCode::Adapters::Openai.new(@config)
  end

  def teardown
    ENV.delete("OPENAI_API_KEY")
  end

  def test_adapter_name
    assert_equal "OpenAI", @adapter.send(:adapter_name)
  end

  def test_api_endpoint
    assert_equal "https://api.openai.com/v1/chat/completions", @adapter.send(:api_endpoint)
  end
end
