## [Unreleased]

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
