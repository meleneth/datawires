# frozen_string_literal: true

module EditAffordances
  class Projection
    Defaults = Struct.new(:column_count, keyword_init: true)

    attr_reader :rows, :screens, :bindings, :defaults, :diagnostics

    def initialize(rows:, screens: [], bindings: [], defaults: Defaults.new(column_count: 12), diagnostics: [])
      @rows = rows.freeze
      @screens = screens.freeze
      @bindings = bindings.freeze
      @defaults = defaults
      @diagnostics = diagnostics.freeze
    end

    def empty?
      rows.empty?
    end
  end
end
