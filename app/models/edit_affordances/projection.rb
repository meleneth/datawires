# frozen_string_literal: true

module EditAffordances
  class Projection
    Defaults = Struct.new(:column_count, keyword_init: true)
    Diagnostic = Struct.new(:severity, :message, :cell_data, keyword_init: true)
    Screen = Struct.new(:id, :title, :root_binding, :root_cursor, :rows, :defaults, :commit_mode, keyword_init: true) do
      def empty?
        rows.empty?
      end
    end

    attr_reader :rows, :screens, :bindings, :defaults, :diagnostics, :start_screen_id

    def initialize(rows:, screens: [], bindings: [], defaults: Defaults.new(column_count: 12), diagnostics: [], start_screen_id: nil)
      @rows = rows.freeze
      @screens = screens.freeze
      @bindings = bindings.freeze
      @defaults = defaults
      @diagnostics = diagnostics.freeze
      @start_screen_id = start_screen_id
    end

    def empty?
      rows.empty?
    end

    def start_screen
      screens.find { |screen| screen.id == start_screen_id } || screens.first
    end
  end
end
