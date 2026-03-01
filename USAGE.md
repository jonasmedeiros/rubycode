# RubyCode - Interactive AI Code Assistant

An OpenCode-inspired AI agent for Ruby/Rails development that can autonomously explore codebases and suggest changes.

## Quick Start

```bash
ruby rubycode_cli.rb
```

You'll be prompted for:
1. **Directory**: Path to your Rails project (default: current directory)
2. **Debug mode**: Enable to see JSON requests/responses (default: no)

## Example Usage

```
💬 You: Change the button color to red

🤖 Agent:
   💻 ls -la
   🔍 button
   📖 app/assets/stylesheets/buttons.css

I found the button styling in `app/assets/stylesheets/buttons.css:15`

To change the button color to red, modify line 15:

```css
/* Change this: */
background-color: blue;

/* To this: */
background-color: red;
```
```

## Available Commands

- **Regular prompts**: Ask questions or request code changes
- **`clear`**: Clear conversation history
- **`exit`** or **`quit`**: Exit the CLI

## How It Works

The agent has access to three safe tools:

1. **bash**: Execute read-only commands (ls, find, cat, etc.)
2. **read**: Read file contents with line numbers
3. **search**: Search for patterns using grep

The agent autonomously decides which tools to use to:
- Understand your codebase
- Find relevant files
- Suggest specific code changes

## Features

✅ **Safe**: Only read-only operations, no destructive commands
✅ **Autonomous**: Agent explores codebase on its own
✅ **Transparent**: See what the agent is doing (enable debug mode)
✅ **Rails-aware**: Optimized for Ruby on Rails projects
✅ **Conversational**: Maintains history across multiple questions

## Architecture

Built following OpenCode's design:
- **Tools**: Controlled, safe operations with validation
- **Agent Loop**: LLM calls tools, we execute, loop until done
- **History**: Maintains conversation context
- **JSON Visibility**: Full transparency in debug mode

## Workaround for Weak Tool-Calling Models

If you're testing with models that have poor tool-calling capabilities (like qwen3-coder), enable the injection workaround:

```ruby
Rubycode.configure do |config|
  config.enable_tool_injection_workaround = true
end
```

**What this does:**
- When the model generates text instead of calling a tool, it injects a reminder message
- Forces the model to keep calling tools until it finds the answer
- **OpenCode does NOT use this** - they rely on strong tool-calling models (Claude, GPT-4)
- This is ONLY for testing/development with weaker models

**When to disable:**
- When using Claude (Anthropic)
- When using GPT-4 (OpenAI)  
- When using Gemini (Google)
- In production
