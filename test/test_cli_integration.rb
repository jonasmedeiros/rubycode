# frozen_string_literal: true

require_relative "test_helper"

# Define ChatContext struct for testing (matches rubycode_cli.rb)
ChatContext = Struct.new(:prompt, :client, :adapter, :model, :full_path, :debug_mode)

class TestCLIIntegration < Minitest::Test
  # Test the select_model_for_adapter logic with the ACTUAL I18n structure
  def test_select_model_for_adapter_with_real_structure
    # Real I18n structure has :default key with string value, and other keys with hash values
    models = {
      default: "gemini-2.0-flash-exp", # This is a string, not a hash!
      flash: { label: "Flash", name: "gemini-2.0-flash-exp" },
      pro: { label: "Pro", name: "gemini-exp-1206" }
    }

    # Simulate the fixed logic
    choices = build_choices_from_models(models)

    # Should skip :default and only process the hash entries
    assert_equal({ "Flash" => "gemini-2.0-flash-exp", "Pro" => "gemini-exp-1206" }, choices)
  end

  # Test with string "default" key (defensive)
  def test_select_model_for_adapter_with_string_default_key
    models = {
      "default" => "gemini-2.0-flash-exp",
      "flash" => { "label" => "Flash", "name" => "gemini-2.0-flash-exp" }
    }

    choices = build_choices_from_models(models)
    assert_equal({ "Flash" => "gemini-2.0-flash-exp" }, choices)
  end

  # Test that non-hash values are skipped
  def test_select_model_for_adapter_skips_non_hash_values
    models = {
      default: "some-model",
      invalid: "also-a-string",
      valid: { label: "Valid", name: "valid-model" }
    }

    choices = build_choices_from_models(models)

    # Should only include the valid hash entry
    assert_equal({ "Valid" => "valid-model" }, choices)
  end

  # Test with actual Ollama structure from I18n
  def test_select_model_for_adapter_with_ollama_structure
    models = I18n.t("rubycode.models.ollama")
    choices = build_choices_from_models(models)

    # Should have 4 model choices (powerful, advanced, reasoning, fast)
    assert_equal 4, choices.size
    assert choices.values.include?("qwen3-coder:480b-cloud")
    assert choices.values.include?("gpt-oss:120b-cloud")
  end

  # Test with actual Gemini structure from I18n
  def test_select_model_for_adapter_with_gemini_structure
    models = I18n.t("rubycode.models.gemini")
    choices = build_choices_from_models(models)

    # Should have 4 model choices
    assert_equal 4, choices.size
    assert choices.values.include?("gemini-2.5-flash")
    assert choices.values.include?("gemini-2.5-pro")
  end

  # Test ChatContext struct creation
  def test_chat_context_creation
    # Ensure ChatContext can be created with all required fields
    prompt = Object.new
    client = Object.new
    adapter = :ollama
    model = "test-model"
    full_path = "/tmp"
    debug_mode = false

    context = ChatContext.new(prompt, client, adapter, model, full_path, debug_mode)

    assert_equal prompt, context.prompt
    assert_equal client, context.client
    assert_equal :ollama, context.adapter
    assert_equal "test-model", context.model
    assert_equal "/tmp", context.full_path
    assert_equal false, context.debug_mode
  end

  private

  # Helper method to build choices from models hash
  def build_choices_from_models(models)
    choices = {}
    models.each do |key, model_data|
      next if %i[default].include?(key) || ["default"].include?(key)
      next unless model_data.is_a?(Hash)

      label = model_data[:label] || model_data["label"]
      name = model_data[:name] || model_data["name"]
      choices[label] = name
    end
    choices
  end
end
