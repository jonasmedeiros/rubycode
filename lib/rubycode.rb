# frozen_string_literal: true

require_relative "rubycode/version"
require_relative "rubycode/errors"
require_relative "rubycode/value_objects"
require_relative "rubycode/configuration"
require_relative "rubycode/history"
require_relative "rubycode/context_builder"
require_relative "rubycode/adapters/base"
require_relative "rubycode/adapters/ollama"
require_relative "rubycode/tools"
require_relative "rubycode/agent_loop"
require_relative "rubycode/client"
require_relative "rubycode/views/welcome"
require_relative "rubycode/views/bash_approval"
require_relative "rubycode/views/write_approval"
require_relative "rubycode/views/update_approval"
require_relative "rubycode/views/skip_notification"
require_relative "rubycode/views/cli/error_message"
require_relative "rubycode/views/cli/configuration_table"
require_relative "rubycode/views/cli/ready_message"
require_relative "rubycode/views/cli/exit_message"
require_relative "rubycode/views/cli/history_cleared_message"
require_relative "rubycode/views/cli/response_box"
require_relative "rubycode/views/cli/interrupt_message"
require_relative "rubycode/views/cli/error_display"
require_relative "rubycode/views/agent_loop/thinking_status"
require_relative "rubycode/views/agent_loop/response_received"
require_relative "rubycode/views/agent_loop/iteration_header"
require_relative "rubycode/views/agent_loop/iteration_footer"
require_relative "rubycode/views/agent_loop/tool_error"

# Rubycode is a Ruby-native AI coding agent with pluggable LLM adapters
module RubyCode
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
