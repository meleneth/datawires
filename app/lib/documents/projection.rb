# frozen_string_literal: true

module Documents
  class Projection
    attr_reader :source, :path, :edit_affordance

    def initialize(source:, path:, edit_affordance: nil)
      @source = source
      @path = path.is_a?(Documents::Path) ? path : Documents::Path.new(path)
      @edit_affordance = edit_affordance
    end

    def cursor
      @cursor ||= Documents::Cursor.new(source:, path:)
    end

    def location_kind
      return :object if cursor.object?
      return :array if cursor.array?

      :scalar
    end
  end
end
