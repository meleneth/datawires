# frozen_string_literal: true

module EditAffordances
  module Cells
    class Section < Field
      def initialize(cursor:, span:, label:, item_rows: nil, widget: "section", help: nil, placeholder: nil, display: {}, schema_entry: nil)
        super
      end
    end
  end
end
