# frozen_string_literal: true

module Drafts
  class ProjectedArrayFieldComponent < ApplicationComponent
    attr_reader :page, :projected_field

    delegate :draft, :edit_affordance, to: :page
    delegate :cursor, :label, to: :projected_field

    def initialize(page:, field:)
      @page = page
      @projected_field = field
    end

    def show_label?
      label
    end

    def label_text
      cursor.name.to_s.humanize
    end

    def items
      Array(cursor.value)
    end

    def empty?
      items.empty?
    end

    def item_count_text
      "#{items.length} item#{'s' unless items.length == 1}"
    end

    def item_cards
      item_cursors.each_with_index.map do |item_cursor, index|
        {
          title: "Item #{index + 1}",
          child_components: child_components_for(item_cursor)
        }
      end
    end

    def add_item_path
      add_document_properties_path(
        draft_id: draft.id,
        ptr: cursor.ptr,
        path: page.cursor.path.to_s,
        edit_affordance_id: edit_affordance&.id
      )
    end

    private

    def item_cursors
      items.each_index.map { |index| cursor.child(index.to_s) }
    end

    def child_components_for(item_cursor)
      target_cursors_for(item_cursor).map do |child_cursor|
        Drafts::ProjectedFieldComponent.new(
          draft: draft,
          field: EditForms::ProjectedField.new(
            cursor: child_cursor,
            span: nil,
            widget: "auto",
            label: true
          ),
          edit_affordance_id: edit_affordance&.id
        )
      end
    end

    def target_cursors_for(item_cursor)
      if item_cursor.object?
        item_cursor.children
      else
        [ item_cursor ]
      end
    end
  end
end
