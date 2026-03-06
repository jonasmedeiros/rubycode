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
- **Pluggable LLM Adapters**: Currently supports Ollama with configurable timeouts and retry logic
- **Built-in Tools**:
  - `bash`: Execute safe bash commands for filesystem exploration
  - `search`: Search file contents using grep with regex support
  - `read`: Read files and directories with line numbers
  - `write`: Create new files with user approval
  - `update`: Edit existing files with user approval
  - `done`: Signal task completion with final answer
- **Persistent Memory**: SQLite-backed conversation history with Sequel ORM
- **Enhanced CLI**: TTY-based interface with formatted output, progress indicators, and approval workflows
- **Resilient Network**: Automatic retry with exponential backoff for LLM requests
- **I18n Support**: Internationalized error messages and UI text
- **Environment Context**: Automatically provides Ruby version, platform, and working directory info

## Requirements

- Ruby 3.1 or higher
- **Chrome or Chromium browser** (required for web_search and fetch tools)

### Installing Chrome/Chromium

**macOS:**
```bash
brew install --cask chromium
# or
brew install --cask google-chrome
```

**Ubuntu/Debian:**
```bash
sudo apt-get update
sudo apt-get install chromium-browser
```

**Windows:**
Download from [chromium.org](https://www.chromium.org/getting-involved/download-chromium/) or [google.com/chrome](https://www.google.com/chrome/)

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

## Usage

### Basic Usage

```ruby
require "rubycode"

# Configure the LLM adapter
RubyCode.configure do |config|
  config.adapter = :ollama
  config.url = "http://localhost:11434"
  config.model = "deepseek-v3.1:671b-cloud"
  config.root_path = Dir.pwd
  config.debug = false
end

# Create a client and ask a question
client = RubyCode::Client.new
response = client.ask(prompt: "Find the User model in the codebase")
puts response
```

### Configuration Options

```ruby
RubyCode.configure do |config|
  config.adapter = :ollama                    # LLM adapter to use
  config.url = "http://localhost:11434"       # Ollama server URL
  config.model = "deepseek-v3.1:671b-cloud"   # Model name
  config.root_path = Dir.pwd                  # Project root directory
  config.debug = false                        # Enable debug output
  config.enable_tool_injection_workaround = true  # Force tool usage (enabled by default)

  # HTTP timeout and retry settings (new in 0.1.3)
  config.http_read_timeout = 120              # Request timeout in seconds (default: 120)
  config.http_open_timeout = 10               # Connection timeout in seconds (default: 10)
  config.max_retries = 3                      # Number of retry attempts (default: 3)
  config.retry_base_delay = 2.0               # Exponential backoff base delay (default: 2.0)
end
```

### Available Tools

The agent has access to six built-in tools:

1. **bash**: Execute safe bash commands including:
   - Directory exploration: `ls`, `pwd`, `find`, `tree`
   - File inspection: `cat`, `head`, `tail`, `wc`, `file`
   - Content search: `grep`, `rg` (ripgrep)
   - Examples: `grep -rn "button" app/views`, `find . -name "*.rb"`
2. **search**: Simplified search wrapper (use bash + grep for more control)
3. **read**: Read files with line numbers or list directory contents
4. **write**: Create new files (requires user approval)
5. **update**: Edit existing files with exact string replacement (requires user approval)
6. **done**: Signal completion and provide the final answer

**Note**: Tool schemas are externalized in `config/tools/*.json` for easy customization.

### New in 0.1.3

- **Persistent Memory**: Conversation history now stored in SQLite database using Sequel ORM
- **Write & Update Tools**: Create and modify files with user approval workflow
- **Network Resilience**: Automatic retry with exponential backoff for failed LLM requests
- **Enhanced CLI**: Improved UI with TTY toolkit, formatted output, and progress indicators
- **I18n Support**: Internationalized error messages and system prompts
- **Improved Architecture**: Separated database connection management, view classes for all UI components
- **Cross-platform Support**: Added Linux platform support for CI/CD environments

## Development

After checking out the repo, run `bundle install` to install dependencies.

To install this gem onto your local machine, run:

```bash
bundle exec rake install
```

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/jonasmedeiros/rubycode.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
