module Editors
  class Dispatcher
    PARTIALS = {
      object: "drafts/editor",
      array: "drafts/editor",
      scalar: "drafts/editor"
    }.freeze

    def initialize(projection:)
      @projection = projection
    end

    def partial
      PARTIALS.fetch(@projection.location_kind)
    end

    def locals
      { projection: @projection }
    end
  end
end
