# frozen_string_literal: true

$LOAD_PATH.unshift File.expand_path("../lib", __dir__)
require "rubycode"

require "minitest/autorun"

module TestHelpers
  # Mock HTTP responses for adapter/search provider tests
  def mock_http_response(status: 200, body: "{}", headers: {})
    response = Net::HTTPResponse.new("1.1", status.to_s, "OK")
    response.instance_variable_set(:@body, body)
    response.instance_variable_set(:@read, true)

    # Set headers
    headers.each do |key, value|
      response[key] = value
    end

    response
  end

  # Mock I18n translations
  def mock_i18n(key, value)
    I18n.backend.store_translations(:en, key => value)
  end

  # Clean database between tests
  def clean_database
    RubyCode::Database.connection[:messages].delete if RubyCode::Database.connected?
    RubyCode::Database.connection[:api_keys].delete if RubyCode::Database.connected?
  end

  # Create a mock TTY prompt that auto-approves
  def mock_tty_prompt(auto_approve: true)
    prompt = Minitest::Mock.new
    prompt.expect(:yes?, auto_approve, [String, Hash]) if auto_approve
    prompt
  end

  # Create a mock approval handler
  def mock_approval_handler(should_approve: true)
    handler = Minitest::Mock.new
    handler.expect(:request_bash_approval, should_approve, [String, String, Array])
    handler.expect(:request_update_approval, should_approve, [String, String, String])
    handler
  end
end

# Include helpers in all test classes
class Minitest::Test
  include TestHelpers
end
