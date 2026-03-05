# frozen_string_literal: true

require_relative "lib/rubycode/version"

Gem::Specification.new do |spec|
  spec.name          = "rubycode"
  spec.version       = RubyCode::VERSION
  spec.authors       = ["Jonas Medeiros"]
  spec.email         = ["jonas.g.medeiros@gmail.com"]

  spec.summary       = "AI coding assistant with autonomous task execution"
  spec.description   = "Ruby-native AI coding agent with pluggable LLM adapters, persistent memory, and file editing tools. Features automatic retry logic, SQLite-backed conversation history, and user approval workflows for file modifications."
  spec.homepage      = "https://github.com/jonasmedeiros/rubycode"
  spec.license       = "MIT"
  spec.required_ruby_version = ">= 3.1.0"

  spec.metadata = {
    "homepage_uri" => "https://github.com/jonasmedeiros/rubycode",
    "source_code_uri" => "https://github.com/jonasmedeiros/rubycode",
    "bug_tracker_uri" => "https://github.com/jonasmedeiros/rubycode/issues",
    "rubygems_mfa_required" => "true"
  }

  # Files included in the gem
  gemspec = File.basename(__FILE__)
  spec.files = IO.popen(%w[git ls-files -z], chdir: __dir__, err: IO::NULL) do |ls|
    ls.readlines("\x0", chomp: true).reject do |f|
      (f == gemspec) ||
        f.end_with?(".gem") ||
        f.start_with?(*%w[bin/ test/ spec/ features/ .git .github appveyor Gemfile])
    end
  end

  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  # I18n for internationalization
  spec.add_dependency "i18n", "~> 1.14"

  # Sequel ORM for persistent conversation memory
  spec.add_dependency "sequel", "~> 5.87"
  spec.add_dependency "sqlite3", "~> 2.4"

  # TTY toolkit dependencies for enhanced CLI
  spec.add_dependency "pastel", "~> 0.8"
  spec.add_dependency "tty-box", "~> 0.7"
  spec.add_dependency "tty-logger", "~> 0.6"
  spec.add_dependency "tty-markdown", "~> 0.7"
  spec.add_dependency "tty-pager", "~> 0.14"
  spec.add_dependency "tty-progressbar", "~> 0.18"
  spec.add_dependency "tty-prompt", "~> 0.23"
  spec.add_dependency "tty-spinner", "~> 0.9"
  spec.add_dependency "tty-table", "~> 0.12"
end
