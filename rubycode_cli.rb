#!/usr/bin/env ruby
# frozen_string_literal: true

require_relative "lib/rubycode"
require "tty-prompt"
require "tty-box"
require "tty-table"
require "tty-markdown"
require "pastel"

prompt = TTY::Prompt.new
pastel = Pastel.new
adapter = :ollama

model = "deepseek-v3.1:671b-cloud"
url = "http://localhost:11434"

puts "\n#{RubyCode::Views::Welcome.build}"

directory = prompt.ask("What directory do you want to work on?") do |q|
  q.default Dir.pwd
  q.required false
end
directory = Dir.pwd if directory.nil? || directory.empty?

full_path = File.expand_path(directory)

unless Dir.exist?(full_path)
  puts "\n#{pastel.red("[ERROR]")} Directory '#{full_path}' does not exist!"
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

config_table = TTY::Table.new(
  header: [pastel.bold("Setting"), pastel.bold("Value")],
  rows: [
    ["Directory", full_path],
    ["Model", model],
    ["Debug Mode", debug_mode ? pastel.green("ON") : pastel.dim("OFF")]
  ]
)
puts "\n#{config_table.render(:unicode, padding: [0, 1])}"

client = RubyCode::Client.new(tty_prompt: prompt)

puts "\n#{pastel.green("✓")} #{pastel.bold("Ready!")} You can now ask questions or request code changes."

loop do
  user_input = gets&.chomp
  break if user_input.nil?

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
    response = client.ask(prompt: user_input)

    puts "\n#{pastel.magenta("╔═══ Agent Response ═══")}"

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
