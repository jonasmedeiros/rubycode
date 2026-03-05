#!/usr/bin/env ruby
# frozen_string_literal: true

require_relative "lib/rubycode"
require "tty-prompt"
require "tty-box"
require "tty-table"
require "tty-markdown"
require "pastel"

# Initialize TTY components
prompt = TTY::Prompt.new
pastel = Pastel.new

# Display welcome panel
welcome = TTY::Box.frame(
  width: 80,
  border: :thick,
  title: { top_left: " RubyCode v#{RubyCode::VERSION} " }
) do
  [
    pastel.bold.cyan("AI Ruby/Rails Code Assistant"),
    "",
    "Built with: #{pastel.dim("Ollama + DeepSeek + TTY Toolkit")}",
    pastel.dim("─" * 76),
    "#{pastel.yellow("Commands:")} exit, quit, clear"
  ].join("\n")
end
puts "\n#{welcome}"

# Ask for directory
directory = prompt.ask("What directory do you want to work on?") do |q|
  q.default Dir.pwd
  q.required false
end
directory = Dir.pwd if directory.nil? || directory.empty?

# Resolve the full path
full_path = File.expand_path(directory)

unless Dir.exist?(full_path)
  puts "\n#{pastel.red("[ERROR]")} Directory '#{full_path}' does not exist!"
  exit 1
end

# Ask if debug mode should be enabled
debug_mode = prompt.yes?("Enable debug mode?") do |q|
  q.default false
end

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

# Display configuration as table
config_table = TTY::Table.new(
  header: [pastel.bold("Setting"), pastel.bold("Value")],
  rows: [
    ["Directory", full_path],
    ["Model", "deepseek-v3.1:671b-cloud"],
    ["Debug Mode", debug_mode ? pastel.green("ON") : pastel.dim("OFF")]
  ]
)
puts "\n#{config_table.render(:unicode, padding: [0, 1])}"

# Create a client
client = RubyCode::Client.new

puts "\n#{pastel.green("✓")} #{pastel.bold("Ready!")} You can now ask questions or request code changes."

# Interactive loop with fixed input area at bottom
loop do
  # Draw input area border and prompt
  puts ""
  puts pastel.dim("─" * 80)
  print pastel.cyan("You: ")

  user_input = gets&.chomp

  # Handle empty input
  if user_input.nil? || user_input.strip.empty?
    # Move up and clear the input area we just drew
    print "\e[A\e[2K\e[A\e[2K"
    next
  end

  # Move cursor up to content area (above the input border)
  # This ensures all agent output appears above the input line
  print "\e[A\e[A" # Move up 2 lines (past "You:" and border)
  print "\e[2K"    # Clear the border line
  print "\e[A"     # Move up one more to content area
  puts ""          # Start fresh line for content

  # Handle commands
  case user_input.strip.downcase
  when "exit", "quit"
    puts "\n#{pastel.green("Goodbye!")}\n"
    break
  when "clear"
    client.clear_history
    puts "#{pastel.yellow("✓")} History cleared!"
    next
  end

  begin
    # Get response from agent - all output will appear in content area
    response = client.ask(prompt: user_input)

    # Render response with markdown formatting
    puts "\n#{pastel.magenta("╔═══ Agent Response ═══")}"

    # Try to parse as markdown, fallback to plain
    begin
      rendered = TTY::Markdown.parse(response, width: 80)
      puts rendered
    rescue StandardError
      puts response
    end

    puts pastel.magenta("╚══════════════════════")
  rescue Interrupt
    puts "\n#{pastel.yellow("[INTERRUPTED]")} Type 'exit' to quit or continue chatting."
  rescue StandardError => e
    puts "\n#{pastel.red("[ERROR]")} #{e.message}"
    puts pastel.dim(e.backtrace.first(3).join("\n"))
  end
end
