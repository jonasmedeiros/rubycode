#!/usr/bin/env ruby
# frozen_string_literal: true

require_relative "lib/rubycode"
require "tty-prompt"

prompt = TTY::Prompt.new
adapter = :ollama

model = "deepseek-r1:8b"
url = "http://localhost:11434"

puts "\n#{RubyCode::Views::Welcome.build}"

directory = prompt.ask("What directory do you want to work on?") do |q|
  q.default Dir.pwd
  q.required false
end
directory = Dir.pwd if directory.nil? || directory.empty?

full_path = File.expand_path(directory)

unless Dir.exist?(full_path)
  puts RubyCode::Views::Cli::ErrorMessage.build(message: "Directory '#{full_path}' does not exist!")
  exit 1
end

debug_mode = prompt.yes?("Enable debug mode?") do |q|
  q.default false
end

RubyCode.configure do |config|
  config.adapter = adapter
  config.url = url
  config.model = model
  config.root_path = full_path
  config.debug = debug_mode

  config.enable_tool_injection_workaround = true
end

puts RubyCode::Views::Cli::ConfigurationTable.build(
  directory: full_path,
  model: model,
  debug_mode: debug_mode
)

client = RubyCode::Client.new(tty_prompt: prompt)

puts RubyCode::Views::Cli::ReadyMessage.build

loop do
  user_input = begin
    prompt.ask("You: ")
  rescue StandardError
    nil
  end
  break if user_input.nil?

  case user_input.strip.downcase
  when "exit", "quit"
    puts RubyCode::Views::Cli::ExitMessage.build
    break
  when "clear"
    client.clear_memory
    puts RubyCode::Views::Cli::MemoryClearedMessage.build
    next
  end

  begin
    response = client.ask(prompt: user_input)
    puts RubyCode::Views::Cli::ResponseBox.build(response: response)
  rescue Interrupt
    puts RubyCode::Views::Cli::InterruptMessage.build
  rescue StandardError => e
    puts RubyCode::Views::Cli::ErrorDisplay.build(error: e)
  end
end
