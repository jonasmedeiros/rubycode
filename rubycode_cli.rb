#!/usr/bin/env ruby
# frozen_string_literal: true

require_relative "lib/rubycode"
require "readline"

puts "\n#{"=" * 80}"
puts "🚀 RubyCode - AI Ruby/Rails Code Assistant"
puts "=" * 80

# Ask for directory
print "\nWhat directory do you want to work on? (default: current directory): "
directory = gets.chomp
directory = Dir.pwd if directory.empty?

# Resolve the full path
full_path = File.expand_path(directory)

unless Dir.exist?(full_path)
  puts "\n❌ Error: Directory '#{full_path}' does not exist!"
  exit 1
end

puts "\n📁 Working directory: #{full_path}"

# Ask if debug mode should be enabled
print "Enable debug mode? (shows JSON requests/responses) [y/N]: "
debug_input = gets.chomp.downcase
debug_mode = %w[y yes].include?(debug_input)

# Configure the client
RubyCode.configure do |config|
  config.adapter = :ollama
  config.url = "http://localhost:11434"
  config.model = "deepseek-v3.1:671b-cloud"
  config.root_path = full_path
  config.debug = debug_mode

  # Enable workaround to force tool-calling for models that don't follow instructions
  config.enable_tool_injection_workaround = true
end

puts "🐛 Debug mode: #{debug_mode ? "ON" : "OFF"}" if debug_mode

# Create a client
client = RubyCode::Client.new

puts "\n#{"=" * 80}"
puts "✨ Agent initialized! You can now ask questions or request code changes."
puts "   Type 'exit' or 'quit' to exit, 'clear' to clear history"
puts "=" * 80

# Interactive loop
loop do
  print "\n💬 You: "
  prompt = Readline.readline("", true)

  # Handle empty input
  next if prompt.nil? || prompt.strip.empty?

  # Handle commands
  case prompt.strip.downcase
  when "exit", "quit"
    puts "\n👋 Goodbye!"
    break
  when "clear"
    client.clear_history
    puts "\n🗑️  History cleared!"
    next
  end

  puts "\n#{"-" * 80}"

  begin
    # Get response from agent
    response = client.ask(prompt: prompt)

    puts "\n🤖 Agent:"
    puts "-" * 80
    puts response
    puts "-" * 80
  rescue Interrupt
    puts "\n\n⚠️  Interrupted! Type 'exit' to quit or continue chatting."
  rescue StandardError => e
    puts "\n❌ Error: #{e.message}"
    puts e.backtrace.first(3).join("\n")
  end
end
