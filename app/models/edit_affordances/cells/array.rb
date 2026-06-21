# frozen_string_literal: true

module EditAffordances
  module Cells
    class Array < Field
      attr_reader :collection

      def initialize(
        cursor:,
        span:,
        label:,
        item_rows: nil,
        widget: "array",
        help: nil,
        placeholder: nil,
        display: {},
        collection: nil
      )
        @collection = collection.is_a?(EditAffordances::Collection) ? collection : EditAffordances::Collection.new(collection)
        super(
          cursor: cursor,
          span: span,
          widget: widget,
          label: label,
          item_rows: item_rows,
          help: help,
          placeholder: placeholder,
          display: display
        )
      end
    end
  end
end
