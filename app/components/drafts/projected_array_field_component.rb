# frozen_string_literal: true

module Drafts
  class ProjectedArrayFieldComponent < ApplicationComponent
    attr_reader :page, :projected_field

    delegate :draft, :edit_affordance, to: :page
    delegate :cursor, :label, :help, :display, :collection, :item_rows, to: :projected_field

    def initialize(page:, field:)
      @page = page
      @projected_field = field
    end

    def show_label?
      label
    end

    def label_text
      projected_field.default_label
    end

    def help_text
      help.presence
    end

    def required?
      projected_field.required?
    end

    def compact?
      display.is_a?(Hash) && display["compact"] == true
    end

    def wrapper_class
      compact? ? "space-y-2" : "space-y-3"
    end

    def table_presentation?
      collection.presentation == "table"
    end

    def cards_presentation?
      collection.presentation == "cards"
    end

    def empty?
      item_links.empty?
    end

    def item_count_text
      "#{item_links.length} item#{'s' unless item_links.length == 1}"
    end

    def add_item_path
      add_item_draft_path(draft)
    end

    def remove_item_path
      remove_item_draft_path(draft)
    end

    def reorder_item_path
      reorder_item_draft_path(draft)
    end

    def add_item_button_params
      {
        ptr: cursor.ptr,
        edit_affordance_id: edit_affordance&.id,
        collection_creation: collection.creation,
        collection_navigation: collection.navigation,
        collection_item_screen: collection.item_screen
      }
    end

    def show_add_item_button?
      !inline_blank_form?
    end

    def inline_blank_form?
      collection.inline_blank_form?
    end

    def delete_enabled?
      collection.delete_enabled?
    end

    def reorder_enabled?
      collection.reorder_enabled?
    end

    def new_item_fields
      @new_item_fields ||= custom_new_item_fields.presence || generated_new_item_fields
    end

    def item_links
      @item_links ||= item_cursors.each_with_index.map do |item_cursor, index|
        {
          title: item_title(item_cursor, index),
          value_label: collection.item_subtitle_for(item_cursor),
          path: draft_path_for(item_cursor),
          remove_params: remove_item_button_params(index),
          move_up_params: reorder_item_button_params(index, "up"),
          move_down_params: reorder_item_button_params(index, "down"),
          first: index.zero?,
          last: index == item_cursors.length - 1
        }
      end
    end

    private

    def item_cursors
      Array(cursor.value).each_index.map { |index| cursor.child(index.to_s) }
    end

    def new_item_cursors
      item_cursor = cursor.child(Array(cursor.value).length.to_s)
      return item_cursor.children.select(&:scalar?) if item_cursor.object?

      [ item_cursor ].select(&:scalar?)
    end

    def generated_new_item_fields
      new_item_cursors.map do |field_cursor|
        EditAffordances::Cells::Field.new(
          cursor: field_cursor,
          span: 12,
          widget: "auto",
          label: true,
          schema_entry: schema_inventory.entry_for(field_cursor)
        )
      end
    end

    def custom_new_item_fields
      Array(item_rows).flatten.filter_map do |cell_data|
        next unless cell_data.is_a?(Hash) && cell_data["binding"].is_a?(Hash)

        field_cursor = cursor_for_item_cell(cell_data)
        next unless field_cursor&.scalar?

        EditAffordances::Cells::Field.new(
          cursor: field_cursor,
          span: cell_data["span"] || 12,
          widget: cell_data["widget"] || "auto",
          label: cell_data.key?("label") ? cell_data["label"] : true,
          help: cell_data["help"],
          placeholder: cell_data["placeholder"],
          display: cell_data["display"],
          reference: cell_data["reference"],
          schema_entry: schema_inventory.entry_for(field_cursor)
        )
      end
    end

    def cursor_for_item_cell(cell_data)
      binding = cell_data.fetch("binding")
      return nil unless binding["kind"] == "document_ptr"

      relative_path = Documents::Path.new(binding.fetch("ptr"))
      relative_path.tokens.reduce(new_item_cursor) do |memo, token|
        memo.child(token)
      end
    rescue KeyError, Documents::Path::InvalidPathError
      nil
    end

    def new_item_cursor
      @new_item_cursor ||= cursor.child(Array(cursor.value).length.to_s)
    end

    def schema_inventory
      @schema_inventory ||= SchemaPaths::Inventory.new(root_cursor: cursor)
    end

    def item_title(item_cursor, index)
      collection.item_title_for(item_cursor, fallback: "Item #{index + 1}")
    end

    def remove_item_button_params(index)
      params = {
        ptr: cursor.ptr,
        index: index,
        path: cursor.path.to_s
      }
      params[:edit_affordance_id] = edit_affordance.id if edit_affordance&.id
      params
    end

    def reorder_item_button_params(index, direction)
      remove_item_button_params(index).merge(direction: direction)
    end

    def draft_path_for(item_cursor)
      params = { path: item_cursor.path.to_s }
      params[:edit_affordance_id] = edit_affordance.id if edit_affordance&.id
      params[:screen] = collection.item_screen if collection.item_screen

      draft_path(draft, params)
    end
  end
end
