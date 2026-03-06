# frozen_string_literal: true

require "test_helper"

# NOTE: Tests mock search_duckduckgo and url_exists? methods,
# so Ferrum browser is not initialized during tests

class MockApprovalHandler
  attr_accessor :should_approve

  def initialize(should_approve: true)
    @should_approve = should_approve
  end

  def request_web_search_approval(_query, _max_results)
    @should_approve
  end
end

class TestWebSearch < Minitest::Test
  def setup
    @approval_handler = MockApprovalHandler.new(should_approve: true)
    @context = {
      root_path: Dir.pwd,
      approval_handler: @approval_handler
    }
    @search_tool = RubyCode::Tools::WebSearch.new(context: @context)
  end

  def test_tool_definition_exists
    definition = RubyCode::Tools::WebSearch.definition
    assert_equal "web_search", definition[:function][:name]
    assert_includes definition[:function][:description], "Search the web"
  end

  def test_required_parameters
    definition = RubyCode::Tools::WebSearch.definition
    required = definition[:function][:parameters][:required]
    assert_equal ["query"], required
  end

  def test_search_with_real_query
    fake_results = mock_search_results
    @search_tool.define_singleton_method(:search_duckduckgo) { |_q, _m| fake_results }
    result = @search_tool.execute({ "query" => "Ruby programming", "max_results" => 3 })

    assert_instance_of RubyCode::ToolResult, result
    assert result.metadata[:result_count].positive?
    assert_includes result.content, "URL:"
  end

  def test_missing_query_parameter_raises_tool_error
    error = assert_raises(RubyCode::ToolError) do
      @search_tool.execute({})
    end
    assert_match(/Missing required parameter: query/, error.message)
  end

  def test_user_cancellation_raises_tool_error
    @approval_handler.should_approve = false

    error = assert_raises(RubyCode::ToolError) do
      @search_tool.execute({ "query" => "test" })
    end
    assert_match(/USER CANCELLED/, error.message)
  end

  def test_default_max_results_is_five
    # Mock the search process to check max_results
    search_called = false
    expected_max_results = nil

    @search_tool.define_singleton_method(:search_duckduckgo) do |_query, max_results|
      search_called = true
      expected_max_results = max_results
      []
    end

    @search_tool.execute({ "query" => "test" })

    assert search_called
    assert_equal 5, expected_max_results
  end

  def test_custom_max_results
    search_called = false
    expected_max_results = nil

    @search_tool.define_singleton_method(:search_duckduckgo) do |_query, max_results|
      search_called = true
      expected_max_results = max_results
      []
    end

    @search_tool.execute({ "query" => "test", "max_results" => 10 })

    assert search_called
    assert_equal 10, expected_max_results
  end

  private

  def mock_search_results
    [
      { title: "Ruby Programming Language", url: "https://www.ruby-lang.org/en/",
        snippet: "Ruby is a dynamic programming language" },
      { title: "Ruby Wikipedia", url: "https://en.wikipedia.org/wiki/Ruby_(programming_language)",
        snippet: "Ruby is an interpreted high-level language" },
      { title: "Ruby Guide", url: "https://www.rubyguides.com/", snippet: "Learn Ruby programming" }
    ]
  end
end

# Test class for WebSearch internal methods
class TestWebSearchInternals < Minitest::Test
  def setup
    @approval_handler = MockApprovalHandler.new(should_approve: true)
    @context = {
      root_path: Dir.pwd,
      approval_handler: @approval_handler
    }
    @search_tool = RubyCode::Tools::WebSearch.new(context: @context)
  end

  def test_parse_search_results_extracts_data
    html = build_search_html([
                               { url: "https://example.com", title: "Example Title",
                                 snippet: "This is an example snippet." },
                               { url: "https://test.com", title: "Test Title", snippet: "This is a test snippet." }
                             ])
    results = @search_tool.send(:parse_search_results, html)

    assert_equal 2, results.length
    assert_equal "Example Title", results[0][:title]
    assert_equal "Test Title", results[1][:title]
  end

  def test_parse_search_results_handles_missing_snippet
    html = <<~HTML
      <html>
        <body>
          <div class="result">
            <a class="result__a" href="https://example.com">Example Title</a>
          </div>
        </body>
      </html>
    HTML

    results = @search_tool.send(:parse_search_results, html)

    assert_equal 1, results.length
    assert_equal "", results[0][:snippet]
  end

  def test_parse_search_results_skips_results_without_title
    html = <<~HTML
      <html>
        <body>
          <div class="result">
            <div class="result__snippet">Snippet without title</div>
          </div>
          <div class="result">
            <a class="result__a" href="https://example.com">Valid Result</a>
          </div>
        </body>
      </html>
    HTML

    results = @search_tool.send(:parse_search_results, html)

    assert_equal 1, results.length
    assert_equal "Valid Result", results[0][:title]
  end

  def test_normalize_url_converts_relative_to_absolute
    url = "//example.com/path"
    normalized = @search_tool.send(:normalize_url, url)
    assert_equal "https://example.com/path", normalized
  end

  def test_normalize_url_keeps_absolute_urls
    url = "https://example.com/path"
    normalized = @search_tool.send(:normalize_url, url)
    assert_equal "https://example.com/path", normalized
  end

  def test_normalize_url_returns_nil_for_nil
    normalized = @search_tool.send(:normalize_url, nil)
    assert_nil normalized
  end

  def test_extract_result_data_returns_nil_without_title
    html = Nokogiri::HTML("<div class='result'></div>")
    result_div = html.at_css(".result")

    result = @search_tool.send(:extract_result_data, result_div)

    assert_nil result
  end

  def test_extract_result_data_returns_hash_with_title
    html = Nokogiri::HTML(<<~HTML)
      <div class='result'>
        <a class='result__a' href='https://example.com'>Title</a>
        <div class='result__snippet'>Snippet text</div>
      </div>
    HTML
    result_div = html.at_css(".result")

    result = @search_tool.send(:extract_result_data, result_div)

    assert_equal "Title", result[:title]
    assert_equal "https://example.com", result[:url]
    assert_equal "Snippet text", result[:snippet]
  end

  def test_format_results_returns_no_results_message_when_empty
    result = @search_tool.send(:format_results, [])

    assert_instance_of RubyCode::ToolResult, result
    assert_equal "No results found", result.content
  end

  def test_format_results_formats_multiple_results
    results = [
      { title: "First", url: "https://first.com", snippet: "First snippet" },
      { title: "Second", url: "https://second.com", snippet: "Second snippet" }
    ]

    result = @search_tool.send(:format_results, results)

    assert_instance_of RubyCode::ToolResult, result
    assert_match(%r{1\. First.*URL: https://first\.com.*First snippet}m, result.content)
    assert_match(%r{2\. Second.*URL: https://second\.com.*Second snippet}m, result.content)
    assert_equal 2, result.metadata[:result_count]
  end

  def test_verify_results_filters_dead_links
    results = [
      { title: "Result 1", url: "https://example.com/1", snippet: "Snippet 1" },
      { title: "Result 2", url: "https://example.com/2", snippet: "Snippet 2" },
      { title: "Result 3", url: "https://example.com/3", snippet: "Snippet 3" }
    ]

    # Mock url_exists? to return true only for result 1 and 3
    call_count = 0
    @search_tool.define_singleton_method(:url_exists?) do |url|
      call_count += 1
      url.end_with?("/1") || url.end_with?("/3")
    end

    verified = @search_tool.send(:verify_results, results, 2)

    assert_equal 2, verified.length
    assert_equal "Result 1", verified[0][:title]
    assert_equal "Result 3", verified[1][:title]
  end

  def test_verify_results_stops_after_reaching_max
    results = (1..10).map do |i|
      { title: "Result #{i}", url: "https://example.com/#{i}", snippet: "Snippet #{i}" }
    end

    # Mock all URLs as valid
    @search_tool.define_singleton_method(:url_exists?) { |_url| true }

    verified = @search_tool.send(:verify_results, results, 3)

    assert_equal 3, verified.length
  end

  def test_url_exists_returns_true_for_success
    mock_page = create_mock_page(status: 200)
    mock_browser = create_mock_browser_with_page(mock_page)

    RubyCode::BrowserManager.stub :browser, mock_browser do
      assert @search_tool.send(:url_exists?, "https://httpbin.org/status/200")
    end
  end

  def test_url_exists_returns_false_for_not_found
    mock_page = create_mock_page(status: 404)
    mock_browser = create_mock_browser_with_page(mock_page)

    RubyCode::BrowserManager.stub :browser, mock_browser do
      refute @search_tool.send(:url_exists?, "https://httpbin.org/status/404")
    end
  end

  def test_url_exists_returns_false_for_invalid_url
    mock_browser = Object.new
    mock_browser.define_singleton_method(:create_page) { raise StandardError, "Network error" }

    RubyCode::BrowserManager.stub :browser, mock_browser do
      refute @search_tool.send(:url_exists?, "https://this-domain-does-not-exist-12345.com")
    end
  end

  private

  def build_search_html(items)
    results = items.map do |item|
      "<div class=\"result\">" \
        "<a class=\"result__a\" href=\"#{item[:url]}\">#{item[:title]}</a>" \
        "<div class=\"result__snippet\">#{item[:snippet]}</div></div>"
    end.join
    "<html><body>#{results}</body></html>"
  end

  def create_mock_page(status:)
    mock_network = Object.new
    mock_network.define_singleton_method(:status) { status }

    mock_page = Object.new
    mock_page.define_singleton_method(:go_to) { |_url| }
    mock_page.define_singleton_method(:network) { mock_network }
    mock_page.define_singleton_method(:close) {}

    mock_page
  end

  def create_mock_browser_with_page(page)
    mock_browser = Object.new
    mock_browser.define_singleton_method(:create_page) { page }
    mock_browser
  end
end
