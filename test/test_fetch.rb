# frozen_string_literal: true

require "test_helper"

# NOTE: Tests mock fetch_url method, so Ferrum browser is not initialized during tests
class TestFetch < Minitest::Test
  def setup
    @context = { root_path: Dir.pwd }
    @fetch_tool = RubyCode::Tools::Fetch.new(context: @context)
  end

  def test_tool_definition_exists
    definition = RubyCode::Tools::Fetch.definition
    assert_equal "fetch", definition[:function][:name]
    assert_includes definition[:function][:description], "Fetch HTML content"
  end

  def test_required_parameters
    definition = RubyCode::Tools::Fetch.definition
    required = definition[:function][:parameters][:required]
    assert_equal ["url"], required
  end

  def test_fetch_html_from_httpbin
    # Mock the HTTP response
    mock_html = <<~HTML
      <!DOCTYPE html>
      <html>
        <body>
          <h1>Herman Melville - Moby-Dick</h1>
          <p>Call me Ishmael.</p>
        </body>
      </html>
    HTML

    @fetch_tool.define_singleton_method(:fetch_url) { |_url| mock_html }

    result = @fetch_tool.execute({ "url" => "https://httpbin.org/html" })

    assert_instance_of RubyCode::ToolResult, result
    assert result.content.bytesize.positive?
    assert_includes result.content, "Herman Melville"
  end

  def test_fetch_with_text_extraction
    # Mock the HTTP response
    mock_html = <<~HTML
      <!DOCTYPE html>
      <html>
        <head><title>Moby-Dick</title></head>
        <body>
          <h1>Herman Melville - Moby-Dick</h1>
          <p>Call me Ishmael.</p>
        </body>
      </html>
    HTML

    @fetch_tool.define_singleton_method(:fetch_url) { |_url| mock_html }

    result = @fetch_tool.execute({
                                   "url" => "https://httpbin.org/html",
                                   "extract_text" => true
                                 })

    assert_instance_of RubyCode::ToolResult, result
    assert_includes result.content, "Moby-Dick"
    refute_includes result.content, "<html>"
  end

  def test_invalid_url_raises_url_error
    error = assert_raises(RubyCode::URLError) do
      @fetch_tool.execute({ "url" => "not-a-valid-url" })
    end
    assert_match(/URL must have http or https scheme/, error.message)
  end

  def test_missing_url_parameter_raises_tool_error
    error = assert_raises(RubyCode::ToolError) do
      @fetch_tool.execute({})
    end
    assert_match(/Missing required parameter: url/, error.message)
  end

  def test_url_without_scheme_raises_error
    error = assert_raises(RubyCode::URLError) do
      @fetch_tool.execute({ "url" => "www.example.com" })
    end
    assert_match(/URL must have http or https scheme/, error.message)
  end

  def test_url_without_hostname_raises_error
    error = assert_raises(RubyCode::URLError) do
      @fetch_tool.execute({ "url" => "https://" })
    end
    assert_match(/URL must have a hostname/, error.message)
  end

  def test_http_404_raises_http_error
    # Mock fetch_url to raise an HTTPError
    @fetch_tool.define_singleton_method(:fetch_url) do |_url|
      raise RubyCode::HTTPError, "HTTP 404: NOT FOUND"
    end

    error = assert_raises(RubyCode::HTTPError) do
      @fetch_tool.execute({ "url" => "https://httpbin.org/status/404" })
    end
    assert_match(/HTTP 404/, error.message)
  end

  def test_extract_text_content_removes_html_tags
    html = "<html><head><title>Test</title></head><body>" \
           "<script>alert('test');</script><style>body { color: red; }</style>" \
           "<nav>Navigation</nav><h1>Hello World</h1><p>This is a test.</p>" \
           "<footer>Footer</footer></body></html>"

    text = @fetch_tool.send(:extract_text_content, html)

    assert_includes text, "Hello World"
    assert_includes text, "This is a test"
    refute_includes text, "alert('test')"
    refute_includes text, "color: red"
    refute_includes text, "Navigation"
    refute_includes text, "Footer"
  end

  def test_extract_text_content_normalizes_whitespace
    html = <<~HTML
      <html>
        <body>
          <p>Line   with    multiple    spaces</p>
          <p>Line with

          multiple

          newlines</p>
        </body>
      </html>
    HTML

    text = @fetch_tool.send(:extract_text_content, html)

    assert_includes text, "Line with multiple spaces"
    refute_match(/\s{2,}/, text) # No multiple consecutive spaces
  end

  def test_extract_text_content_limits_size
    # Create HTML that will exceed 50KB when extracted
    large_text = "A" * 60_000
    html = "<html><body><p>#{large_text}</p></body></html>"

    text = @fetch_tool.send(:extract_text_content, html)

    assert text.bytesize <= (50 * 1024) + 100 # Allow some overhead for truncation message
    assert_includes text, "Content truncated"
  end

  def test_extract_text_content_returns_empty_for_no_body
    html = "<html><head><title>No body</title></head></html>"

    text = @fetch_tool.send(:extract_text_content, html)

    assert_equal "", text
  end

  def test_validate_url_accepts_http
    assert_nil @fetch_tool.send(:validate_url!, "http://example.com")
  end

  def test_validate_url_accepts_https
    assert_nil @fetch_tool.send(:validate_url!, "https://example.com")
  end

  def test_validate_url_rejects_ftp
    error = assert_raises(RubyCode::URLError) do
      @fetch_tool.send(:validate_url!, "ftp://example.com")
    end
    assert_match(/URL must have http or https scheme/, error.message)
  end

  def test_default_extract_text_is_false
    # Mock fetch_url to return simple HTML
    @fetch_tool.define_singleton_method(:fetch_url) do |_url|
      "<html><body><h1>Test</h1></body></html>"
    end

    result = @fetch_tool.execute({ "url" => "https://example.com" })

    # Should return full HTML, not extracted text
    assert_includes result.content, "<html>"
    assert_includes result.content, "<body>"
  end
end
