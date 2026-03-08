# frozen_string_literal: true

module RubyCode
  # Explorer engine that spawns a sub-agent for autonomous codebase exploration
  class Explorer
    MAX_ITERATIONS = 15
    ALLOWED_TOOLS = %w[bash read search web_search fetch done].freeze

    def initialize(adapter:, config:, query:, max_iterations: 10)
      @adapter = adapter
      @config = config
      @query = query
      @max_iterations = max_iterations.clamp(1, MAX_ITERATIONS)
      @memory = Memory.new
    end

    def explore
      # Add user query to memory
      @memory.add_message(role: "user", content: @query)

      # Build and run constrained agent loop
      agent_loop = build_constrained_loop

      puts "\n🔍 Exploring codebase...\n"
      result = agent_loop.run

      puts "\n✓ Exploration complete\n\n"

      result
    end

    private

    def build_constrained_loop
      # Load exploration prompt
      system_prompt = File.read(File.join(__dir__, "../../config/exploration_prompt.md"))

      AgentLoop.new(
        adapter: @adapter,
        memory: @memory,
        config: @config,
        system_prompt: system_prompt,
        options: {
          max_iterations: @max_iterations,
          allowed_tools: ALLOWED_TOOLS,
          read_files: Set.new,
          tty_prompt: TTY::Prompt.new,
          approval_handler: create_explorer_approval_handler
        }
      )
    end

    def create_explorer_approval_handler
      # Create approval handler for web_search and fetch (bash is still approved per safe-list)
      Client::ApprovalHandler.new(
        tty_prompt: TTY::Prompt.new,
        config: @config
      )
    end
  end
end
