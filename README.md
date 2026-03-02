# RubyCode

[![Gem Version](https://badge.fury.io/rb/rubycode.svg)](https://badge.fury.io/rb/rubycode)
[![GitHub](https://img.shields.io/github/license/jonasmedeiros/rubycode)](https://github.com/jonasmedeiros/rubycode)

A Ruby-native AI coding assistant with pluggable LLM adapters. RubyCode provides an agent-based system that can explore codebases, search files, execute commands, and assist with coding tasks.

**GitHub Repository**: [github.com/jonasmedeiros/rubycode](https://github.com/jonasmedeiros/rubycode)

## Features

- **AI Agent Loop**: Autonomous task execution with tool calling
- **Pluggable LLM Adapters**: Currently supports Ollama, easily extendable to other LLMs
- **Built-in Tools**:
  - `bash`: Execute safe bash commands for filesystem exploration
  - `search`: Search file contents using grep with regex support
  - `read`: Read files and directories with line numbers
  - `done`: Signal task completion with final answer
- **Conversation History**: Maintains context across interactions
- **Environment Context**: Automatically provides Ruby version, platform, and working directory info

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
end
```

### Available Tools

The agent has access to four built-in tools:

1. **bash**: Execute safe bash commands including:
   - Directory exploration: `ls`, `pwd`, `find`, `tree`
   - File inspection: `cat`, `head`, `tail`, `wc`, `file`
   - Content search: `grep`, `rg` (ripgrep)
   - Examples: `grep -rn "button" app/views`, `find . -name "*.rb"`
2. **search**: Simplified search wrapper (use bash + grep for more control)
3. **read**: Read files with line numbers or list directory contents
4. **done**: Signal completion and provide the final answer

**Note**: Tool schemas are externalized in `config/tools/*.json` for easy customization.

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
