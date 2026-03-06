#!/usr/bin/env ruby
# frozen_string_literal: true

require_relative "lib/rubycode"
require "tty-prompt"

prompt = TTY::Prompt.new

# Setup wizard for first-time configuration or reconfiguration
def setup_wizard(prompt)
  puts "\n🔧 Configuration Setup\n\n"

  # 1. Adapter selection
  adapter = prompt.select("Select LLM provider:", {
                            "Ollama (Local)" => :ollama,
                            "Groq (Cloud - Fast & Free)" => :groq
                          })

  # 2. Model selection (per adapter)
  model = case adapter
          when :ollama
            prompt.ask("Ollama model:", default: "deepseek-r1:8b")
          when :groq
            prompt.select("Groq model:", {
                            "llama-3.1-8b-instant (Fast)" => "llama-3.1-8b-instant",
                            "llama-3.1-70b-versatile (Powerful)" => "llama-3.1-70b-versatile",
                            "mixtral-8x7b-32768 (Long context)" => "mixtral-8x7b-32768"
                          })
          end

  # 3. URL (Ollama only, Groq is hardcoded)
  url = case adapter
        when :ollama
          prompt.ask("Ollama URL:", default: "http://localhost:11434")
        when :groq
          "https://api.groq.com/openai/v1/chat/completions"
        end

  # 4. Validate API key if needed
  if adapter == :groq && !ENV["GROQ_API_KEY"]
    puts "\n⚠️  GROQ_API_KEY not set!"
    puts "Get your key: https://console.groq.com/keys"
    puts "Then: export GROQ_API_KEY='gsk_...'\n"
    exit 1
  end

  # 5. Save config
  config = { adapter: adapter, model: model, url: url, debug: false }
  RubyCode::ConfigManager.save(config)

  puts "\n✓ Configuration saved to ~/.rubycode/config.yml\n"
  config
end

# Load or setup configuration
if RubyCode::ConfigManager.exists?
  saved_config = RubyCode::ConfigManager.load
  use_saved = prompt.yes?("Use saved configuration (#{saved_config[:adapter]}/#{saved_config[:model]})?",
                          default: true)
  config = use_saved ? saved_config : setup_wizard(prompt)
  adapter = config[:adapter]
  model = config[:model]
  url = config[:url]
  debug_default = config.fetch(:debug, false)
else
  puts "\n👋 First-time setup!\n"
  config = setup_wizard(prompt)
  adapter = config[:adapter]
  model = config[:model]
  url = config[:url]
  debug_default = false
end

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
  q.default debug_default
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
  adapter: adapter,
  model: model,
  directory: full_path,
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
  when "config"
    # Show current config
    puts RubyCode::Views::Cli::ConfigurationTable.build(
      adapter: adapter,
      model: model,
      directory: full_path,
      debug_mode: debug_mode
    )

    # Reconfigure?
    if prompt.yes?("Reconfigure?", default: false)
      puts "\nRestart rubycode to apply new configuration."
      setup_wizard(prompt)
    end
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
