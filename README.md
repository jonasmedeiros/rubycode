# RubyCode

[![Gem Version](https://badge.fury.io/rb/rubycode.svg)](https://badge.fury.io/rb/rubycode)
[![GitHub](https://img.shields.io/github/license/jonasmedeiros/rubycode)](https://github.com/jonasmedeiros/rubycode)

A Ruby-native AI coding assistant with pluggable LLM adapters. RubyCode provides an agent-based system that can explore codebases, search files, execute commands, and assist with coding tasks.

**GitHub Repository**: [github.com/jonasmedeiros/rubycode](https://github.com/jonasmedeiros/rubycode)

## Demo

![RubyCode in action](docs/images/demo.png)

*RubyCode autonomously exploring a Rails codebase, finding the right file, and suggesting code changes.*

## Features

- **AI Agent Loop**: Autonomous task execution with tool calling
- **Multiple Cloud LLM Adapters**: Support for Ollama Cloud, DeepSeek, Gemini, OpenAI, and OpenRouter
- **Interactive Setup Wizard**: First-time configuration with provider selection and API key management
- **Built-in Tools**:
  - `bash`: Execute safe bash commands for filesystem exploration
  - `search`: Search file contents using grep with regex support
  - `read`: Read files and directories with line numbers
  - `write`: Create new files with user approval
  - `update`: Edit existing files with user approval
  - `web_search`: Search the internet with automatic provider fallback (DuckDuckGo/Brave/Exa)
  - `fetch`: Fetch content from URLs
  - `done`: Signal task completion with final answer
- **Persistent Memory**: SQLite-backed conversation history with Sequel ORM
- **Encrypted API Key Storage**: Secure database storage with AES-256-GCM encryption
- **Configuration Persistence**: Automatic saving and loading of preferences
- **Enhanced CLI**: TTY-based interface with formatted output, progress indicators, and approval workflows
- **Resilient Network**: Automatic retry with exponential backoff and rate limit handling
- **Debug Mode**: Comprehensive request/response logging for adapters and search providers
- **I18n Support**: Internationalized error messages and UI text

## Requirements

- Ruby 3.1 or higher

## Installation

Install the gem by executing:

```bash
gem install rubycode
```

Or add it to your application's Gemfile:

```ruby
gem "rubycode"
```

Then execute:

```bash
bundle install
```

## Quick Start

After installation, you can use RubyCode in your Ruby projects:

```ruby
require "rubycode"

# Configure the LLM adapter
RubyCode.configure do |config|
  config.adapter = :ollama
  config.url = "https://api.ollama.com"
  config.model = "qwen3-coder:480b-cloud"
  config.root_path = Dir.pwd
end

# Create a client and ask a question
client = RubyCode::Client.new
response = client.ask(prompt: "Find the User model in the codebase")
puts response
```

The first time you run RubyCode, an interactive setup wizard will guide you through:
1. Selecting your LLM provider (Ollama Cloud, DeepSeek, Gemini, OpenAI, or OpenRouter)
2. Choosing a model
3. Entering API keys (saved securely with encryption)

Your configuration is automatically saved and reloaded on subsequent runs.

## Usage

### Basic Usage

#### Programmatic Usage

```ruby
require "rubycode"

# Configure the LLM adapter
RubyCode.configure do |config|
  config.adapter = :ollama
  config.url = "https://api.ollama.com"
  config.model = "qwen3-coder:480b-cloud"
  config.root_path = Dir.pwd
end

# Create a client and ask a question
client = RubyCode::Client.new
response = client.ask(prompt: "Find the User model in the codebase")
puts response
```

### Configuration Options

```ruby
RubyCode.configure do |config|
  # LLM Provider Settings
  config.adapter = :ollama                    # :ollama, :deepseek, :gemini, :openai, :openrouter
  config.url = "https://api.ollama.com"       # Provider API URL
  config.model = "qwen3-coder:480b-cloud"     # Model name
  config.root_path = Dir.pwd                  # Project root directory

  # HTTP timeout and retry settings
  config.http_read_timeout = 120              # Request timeout in seconds (default: 120)
  config.http_open_timeout = 10               # Connection timeout in seconds (default: 10)
  config.max_retries = 3                      # Number of retry attempts (default: 3)
  config.retry_base_delay = 2.0               # Exponential backoff base delay (default: 2.0)
end
```

### Supported LLM Providers

| Provider | Models | API Key Required | Notes |
|----------|--------|------------------|-------|
| **Ollama Cloud** | qwen3-coder, deepseek-v3.1, gpt-oss | Yes | Cloud-hosted Ollama models |
| **DeepSeek** | deepseek-chat, deepseek-reasoner | Yes | Fast reasoning models |
| **Google Gemini** | gemini-2.5-flash, gemini-2.5-pro, gemini-3-flash-preview | Yes | Multimodal support |
| **OpenAI** | gpt-4o, gpt-4o-mini, o1 | Yes | GPT models with reasoning |
| **OpenRouter** | claude-sonnet-4.5, claude-opus-4.6, gpt-4o | Yes | Access to multiple providers |

### Available Tools

The agent has access to several built-in tools:

1. **bash**: Execute safe bash commands including:
   - Directory exploration: `ls`, `pwd`, `find`, `tree`
   - File inspection: `cat`, `head`, `tail`, `wc`, `file`
   - Content search: `grep`, `rg` (ripgrep)
   - Examples: `grep -rn "button" app/views`, `find . -name "*.rb"`
2. **search**: Simplified search wrapper (use bash + grep for more control)
3. **read**: Read files with line numbers or list directory contents
4. **write**: Create new files (requires user approval)
5. **update**: Edit existing files with exact string replacement (requires user approval)
6. **web_search**: Search the internet with automatic provider fallback (requires user approval):
   - Primary: Exa.ai (AI-native search, optional with API key)
   - Fallback 1: DuckDuckGo Instant Answer API (free, no API key)
   - Fallback 2: Brave Search API (optional, for better results)
7. **fetch**: Fetch and extract text content from URLs (requires user approval)
8. **done**: Signal completion and provide the final answer

**Note**: Tool schemas are externalized in `config/tools/*.json` for easy customization.

#### Web Search Configuration

**By default** (no setup needed):
- Uses DuckDuckGo Instant Answer API (free, no CAPTCHA)
- Good for factual queries and summaries

**For AI-native search** (optional, recommended):
```bash
# Sign up at https://exa.ai/api
export EXA_API_KEY=your_api_key_here
```

**For better web results** (optional):
```bash
# Sign up at https://brave.com/search/api/
export BRAVE_API_KEY=your_api_key_here
```

### New in 0.1.4

- **Bug Fix**: Agent now properly stops when `done` tool is called, even if tool execution fails
- **Multiple Cloud LLM Adapters**: Support for 5 providers (Ollama Cloud, DeepSeek, Gemini, OpenAI, OpenRouter)
- **Web Search & Fetch Tools**: Internet search with automatic fallback (Exa/DuckDuckGo/Brave)
- **Interactive Setup Wizard**: First-time configuration with guided setup
- **Encrypted API Key Storage**: Secure database storage with AES-256-GCM
- **Configuration Persistence**: Automatic saving/loading of preferences
- **Search Provider Architecture**: Refactored with base class and shared concerns
- **Adapter Architecture**: 66% code reduction with shared HTTP/error handling
- **Debug Mode**: Comprehensive request/response logging
- **Rate Limit Handling**: Automatic retry with 3-attempt limit for 429 errors
- **Expanded Test Coverage**: 141 tests covering adapters, agent loop, configuration, and tools
- **Memory Optimization**: Configurable memory window with tool result pruning

## Development

After checking out the repo, run `bundle install` to install dependencies.

### Running Tests

```bash
# Run all tests
bin/test

# Or with rake
bundle exec rake test

# Run specific test file
bundle exec rake test TEST=test/test_adapters.rb

# Run with RuboCop
bundle exec rake
```

### Installing Locally

To install this gem onto your local machine:

```bash
bundle exec rake install
```

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/jonasmedeiros/rubycode.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
