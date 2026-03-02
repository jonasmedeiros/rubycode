# frozen_string_literal: true

require_relative "lib/rubycode/version"

Gem::Specification.new do |spec|
  spec.name          = "rubycode"
  spec.version       = RubyCode::VERSION
  spec.authors       = ["Jonas Medeiros"]
  spec.email         = ["jonas.g.medeiros@gmail.com"]

  spec.summary       = "Ruby AI code assistant (under development)"
  spec.description   = "Ruby-native AI coding agent with pluggable LLM adapters."
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
end
