## [Unreleased]

## [0.1.4] - 2026-03-07

### Added
- **Multiple Cloud LLM Adapters**: Support for 5 cloud providers (Ollama Cloud, DeepSeek, Gemini, OpenAI, OpenRouter)
- **Web Search & Fetch Tools**: Internet search via DuckDuckGo, Brave, and Exa.ai with automatic fallback
- **Interactive Setup Wizard**: First-time configuration with provider/model selection and API key management
- **Encrypted API Key Storage**: Secure database storage for API keys with AES-256-GCM encryption
- **Configuration Persistence**: Automatic saving and loading of user preferences
- **Search Provider Architecture**: Base class with concerns for HTTP client, error handling, and debugging
- **Adapter Architecture**: Refactored with base class and shared concerns (66% code reduction)
- **Debug Mode**: Comprehensive request/response logging for adapters and search providers
- **Rate Limit Handling**: Automatic detection and retry with 3-attempt limit for 429 errors

### Changed
- **Bash Tool**: Improved with real-time output streaming and non-interactive execution
- **System Prompt**: Added web_search and fetch tool documentation for LLM awareness
- **View Layer**: Enhanced web_search and fetch summaries with full URLs and metadata
- **Search Providers**: Reduced code duplication from ~100 lines per provider to shared base class
- **Adapters**: Reduced from ~900 lines to ~300 lines with shared concerns
- **Memory Management**: Clear conversation history on session start to prevent payload size issues

### Fixed
- **Bash Tool stdin_data Error**: Removed invalid stdin_data option from Open3.popen2e
- **Search Provider Transparency**: Now displays which provider (DuckDuckGo/Brave/Exa) returned results
- **RuboCop Compliance**: Reduced violations from 45 to 39 (all acceptable complexity metrics)
- **Test Suite**: All bash tool tests now passing (80 runs, 231 assertions, 0 errors)

## [0.1.3] - 2026-03-05

### Added
- **Write & Update Tools**: New file creation and editing capabilities with user approval workflow
- **Persistent Memory**: SQLite-backed conversation history using Sequel ORM
- **Network Resilience**: Automatic retry with exponential backoff for failed LLM requests (configurable timeouts and retries)
- **Enhanced CLI**: TTY-based interface with formatted output, progress indicators, and approval prompts
- **I18n Support**: Internationalized error messages and system prompts
- **Comprehensive Test Suite**: Added test coverage for Database, Memory, and Models::Base classes
- **Configuration Options**: HTTP timeout settings (read_timeout, open_timeout, max_retries, retry_base_delay)
- **Cross-platform Support**: Added Linux platform support for CI/CD environments

### Changed
- Migrated from raw SQLite3 to Sequel ORM for better database abstraction
- Separated database connection management from model classes
- Refactored view layer with dedicated view classes for all UI components
- Improved error handling with adapter-specific error classes
- Updated gemspec description to be more comprehensive

### Fixed
- Approval prompt now properly waits for user input instead of auto-declining
- Models::Base.last now properly orders by ID before retrieving
- RuboCop compliance across entire codebase

## [0.1.0] - 2026-02-28

- Initial release
