#!/usr/bin/env ruby
# frozen_string_literal: true

require_relative "lib/rubycode"
require "tty-prompt"

prompt = TTY::Prompt.new

# Setup wizard for first-time configuration or reconfiguration
def setup_wizard(prompt)
  puts RubyCode::Views::Cli::SetupTitle.build

  # 1. Adapter selection
  adapter = prompt.select(I18n.t("rubycode.setup.adapter_prompt"), {
                            I18n.t("rubycode.adapters.ollama.name") => :ollama,
                            I18n.t("rubycode.adapters.deepseek.name") => :deepseek,
                            I18n.t("rubycode.adapters.gemini.name") => :gemini,
                            I18n.t("rubycode.adapters.openai.name") => :openai,
                            I18n.t("rubycode.adapters.openrouter.name") => :openrouter
                          })

  # 2. Model selection (per adapter)
  model = case adapter
          when :ollama
            ollama_models = I18n.t("rubycode.models.ollama")
            prompt.select(I18n.t("rubycode.setup.model_prompt"), {
                            ollama_models[:powerful][:label] => ollama_models[:powerful][:name],
                            ollama_models[:advanced][:label] => ollama_models[:advanced][:name],
                            ollama_models[:reasoning][:label] => ollama_models[:reasoning][:name],
                            ollama_models[:fast][:label] => ollama_models[:fast][:name]
                          })
          when :deepseek
            deepseek_models = I18n.t("rubycode.models.deepseek")
            prompt.select(I18n.t("rubycode.setup.model_prompt"), {
                            deepseek_models[:fast][:label] => deepseek_models[:fast][:name],
                            deepseek_models[:reasoning][:label] => deepseek_models[:reasoning][:name]
                          })
          when :gemini
            gemini_models = I18n.t("rubycode.models.gemini")
            prompt.select(I18n.t("rubycode.setup.model_prompt"), {
                            gemini_models[:fast][:label] => gemini_models[:fast][:name],
                            gemini_models[:lite][:label] => gemini_models[:lite][:name],
                            gemini_models[:powerful][:label] => gemini_models[:powerful][:name],
                            gemini_models[:experimental][:label] => gemini_models[:experimental][:name]
                          })
          when :openai
            openai_models = I18n.t("rubycode.models.openai")
            prompt.select(I18n.t("rubycode.setup.model_prompt"), {
                            openai_models[:fast][:label] => openai_models[:fast][:name],
                            openai_models[:balanced][:label] => openai_models[:balanced][:name],
                            openai_models[:reasoning][:label] => openai_models[:reasoning][:name]
                          })
          when :openrouter
            or_models = I18n.t("rubycode.models.openrouter")
            prompt.select(I18n.t("rubycode.setup.model_prompt"), {
                            or_models[:fast][:label] => or_models[:fast][:name],
                            or_models[:balanced][:label] => or_models[:balanced][:name],
                            or_models[:powerful][:label] => or_models[:powerful][:name],
                            or_models[:alternative][:label] => or_models[:alternative][:name]
                          })
          end

  # 3. URL (configurable for Ollama, hardcoded for others)
  url = case adapter
        when :ollama
          prompt.ask(I18n.t("rubycode.setup.url_prompt"), default: "https://api.ollama.com")
        when :deepseek
          "https://api.deepseek.com/v1/chat/completions"
        when :gemini
          "https://generativelanguage.googleapis.com/v1beta/models"
        when :openai
          "https://api.openai.com/v1/chat/completions"
        when :openrouter
          "https://openrouter.ai/api/v1/chat/completions"
        end

  # 4. Handle API key if needed
  adapter_info = I18n.t("rubycode.adapters.#{adapter}")
  env_var_name = "#{adapter.to_s.upcase}_API_KEY"

  if adapter_info[:requires_key]
    # Check if API key exists in database
    saved_key_exists = RubyCode::Models::ApiKey.key_exists?(adapter: adapter)
    env_key_exists = ENV.fetch(env_var_name, nil)

    if saved_key_exists
      # Ask if they want to use the saved key
      use_saved_key = prompt.yes?(I18n.t("rubycode.setup.use_saved_api_key", adapter: adapter.to_s.upcase),
                                  default: true)

      unless use_saved_key
        # Prompt for new API key
        new_key = prompt.mask("#{I18n.t("rubycode.setup.api_key_prompt", adapter: adapter.to_s.upcase)} " \
                              "#{I18n.t("rubycode.setup.api_key_optional")}")

        RubyCode::Models::ApiKey.save_key(adapter: adapter, api_key: new_key) if new_key && !new_key.empty?
      end
    elsif env_key_exists
      # Ask if they want to save the ENV key to database
      save_to_db = prompt.yes?(I18n.t("rubycode.setup.save_env_key_to_db", adapter: adapter.to_s.upcase),
                               default: true)

      RubyCode::Models::ApiKey.save_key(adapter: adapter, api_key: ENV.fetch(env_var_name, nil)) if save_to_db
    else
      # No saved key and no ENV key - must provide one
      puts RubyCode::Views::Cli::ApiKeyMissing.build(adapter: adapter)

      api_key = prompt.mask(I18n.t("rubycode.setup.api_key_prompt", adapter: adapter.to_s.upcase))

      if api_key.nil? || api_key.empty?
        puts "\n#{I18n.t("rubycode.setup.api_key_required")}\n"
        exit 1
      end

      RubyCode::Models::ApiKey.save_key(adapter: adapter, api_key: api_key)
    end
  end

  # 5. Optional: Configure Exa.ai API key for web search
  configure_exa = prompt.yes?(I18n.t("rubycode.setup.configure_exa"),
                              default: false)

  if configure_exa
    saved_exa_key_exists = RubyCode::Models::ApiKey.key_exists?(adapter: :exa)
    env_exa_key_exists = ENV.fetch("EXA_API_KEY", nil)

    if saved_exa_key_exists
      use_saved_exa = prompt.yes?(I18n.t("rubycode.setup.use_saved_api_key", adapter: "EXA"),
                                  default: true)

      unless use_saved_exa
        new_exa_key = prompt.mask("#{I18n.t("rubycode.setup.api_key_prompt", adapter: "EXA")} " \
                                  "#{I18n.t("rubycode.setup.api_key_optional")}")

        RubyCode::Models::ApiKey.save_key(adapter: :exa, api_key: new_exa_key) if new_exa_key && !new_exa_key.empty?
      end
    elsif env_exa_key_exists
      save_exa_to_db = prompt.yes?(I18n.t("rubycode.setup.save_env_key_to_db", adapter: "EXA"),
                                   default: true)

      RubyCode::Models::ApiKey.save_key(adapter: :exa, api_key: ENV.fetch("EXA_API_KEY", nil)) if save_exa_to_db
    else
      exa_key = prompt.mask("#{I18n.t("rubycode.setup.api_key_prompt", adapter: "EXA")} " \
                            "#{I18n.t("rubycode.setup.api_key_optional")}")

      RubyCode::Models::ApiKey.save_key(adapter: :exa, api_key: exa_key) if exa_key && !exa_key.empty?
    end
  end

  # 6. Save config
  config = { adapter: adapter, model: model, url: url }
  RubyCode::ConfigManager.save(config)

  puts RubyCode::Views::Cli::ConfigSaved.build
  config
end

# Load or setup configuration
if RubyCode::ConfigManager.exists?
  saved_config = RubyCode::ConfigManager.load
  use_saved = prompt.yes?(I18n.t("rubycode.setup.use_saved",
                                 adapter: saved_config[:adapter],
                                 model: saved_config[:model]),
                          default: true)
  config = use_saved ? saved_config : setup_wizard(prompt)
  adapter = config[:adapter]
  model = config[:model]
  url = config[:url]
else
  puts RubyCode::Views::Cli::FirstTimeSetup.build
  config = setup_wizard(prompt)
  adapter = config[:adapter]
  model = config[:model]
  url = config[:url]
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

RubyCode.configure do |config|
  config.adapter = adapter
  config.url = url
  config.model = model
  config.root_path = full_path
end

puts RubyCode::Views::Cli::ConfigurationTable.build(
  adapter: adapter,
  model: model,
  directory: full_path
)

# Ensure database is connected before checking for API keys
RubyCode::Database.connect

# Check if adapter requires API key and ensure it's available
adapter_info = I18n.t("rubycode.adapters.#{adapter}")
if adapter_info[:requires_key]
  env_var_name = "#{adapter.to_s.upcase}_API_KEY"
  db_key_exists = RubyCode::Models::ApiKey.key_exists?(adapter: adapter)
  env_key_exists = ENV.fetch(env_var_name, nil)

  unless db_key_exists || env_key_exists
    # No API key found - prompt user
    puts RubyCode::Views::Cli::ApiKeyMissing.build(adapter: adapter)
    api_key = prompt.mask(I18n.t("rubycode.setup.api_key_prompt", adapter: adapter.to_s.upcase))

    if api_key.nil? || api_key.empty?
      puts "\n#{I18n.t("rubycode.setup.api_key_required")}\n"
      exit 1
    end

    # Save to database
    RubyCode::Models::ApiKey.save_key(adapter: adapter, api_key: api_key)
    puts "\n✓ API key saved\n"
  end
end

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
    if prompt.yes?(I18n.t("rubycode.setup.reconfigure"), default: false)
      puts RubyCode::Views::Cli::RestartMessage.build
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
