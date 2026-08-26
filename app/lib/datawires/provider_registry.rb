# frozen_string_literal: true

module Datawires
  class ProviderRegistry
    def initialize
      @providers = {}
    end

    def register(kind, provider)
      providers[kind.to_s] = provider
    end

    def fetch(kind)
      provider = providers[kind.to_s]
      provider = provider.constantize if provider.is_a?(String)
      provider
    end

    def kinds
      providers.keys.freeze
    end

    def unregister(kind)
      providers.delete(kind.to_s)
    end

    private

    attr_reader :providers
  end

  module Providers
    module_function

    def cards
      @cards ||= ProviderRegistry.new
    end

    def layouts
      @layouts ||= ProviderRegistry.new
    end

    def sections
      @sections ||= ProviderRegistry.new
    end

    def sources
      @sources ||= ProviderRegistry.new
    end

    def renderers
      @renderers ||= ProviderRegistry.new
    end

    def aggregates
      @aggregates ||= ProviderRegistry.new
    end

    def archive_contributors
      @archive_contributors ||= ProviderRegistry.new
    end

    def derived_operations
      @derived_operations ||= ProviderRegistry.new
    end
  end
end
