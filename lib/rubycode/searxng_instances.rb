# frozen_string_literal: true

module RubyCode
  # Manages a list of public SearXNG instances for web search
  module SearXNGInstances
    # List of public SearXNG instances
    # See https://searx.space for more instances
    INSTANCES = [
      "https://searx.be",
      "https://search.sapti.me",
      "https://searx.tiekoetter.com",
      "https://searx.prvcy.eu"
    ].freeze

    # Returns a random instance from the list
    def self.random
      INSTANCES.sample
    end

    # Returns all instances
    def self.all
      INSTANCES
    end
  end
end
