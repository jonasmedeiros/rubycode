# frozen_string_literal: true

require_relative "rubycode/version"
require_relative "rubycode/configuration"
require_relative "rubycode/history"
require_relative "rubycode/context_builder"
require_relative "rubycode/adapters/base"
require_relative "rubycode/adapters/ollama"
require_relative "rubycode/tools"
require_relative "rubycode/client"

# Rubycode is a Ruby-native AI coding agent with pluggable LLM adapters
module Rubycode
  class Error < StandardError; end

  class << self
    attr_accessor :configuration
  end

  def self.configure
    self.configuration ||= Configuration.new
    yield(configuration)
  end

  def self.config
    self.configuration ||= Configuration.new
  end
end
