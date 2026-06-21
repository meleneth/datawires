# frozen_string_literal: true

module Drafts
  class ProjectedArrayFieldComponent < ApplicationComponent
    attr_reader :page, :projected_field

    delegate :draft, :edit_affordance, to: :page
    delegate :cursor, :label, :help, :display, :collection, to: :projected_field

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

    def help_text
      help.presence
    end

    def required?
      cursor.required?
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

    def add_item_button_params
      {
        ptr: cursor.ptr,
        edit_affordance_id: edit_affordance&.id
      }
    end

    def item_links
      @item_links ||= item_cursors.each_with_index.map do |item_cursor, index|
        {
          title: item_title(item_cursor, index),
          value_label: collection.item_subtitle_for(item_cursor),
          path: draft_path_for(item_cursor)
        }
      end
    end

    private

    def item_cursors
      Array(cursor.value).each_index.map { |index| cursor.child(index.to_s) }
    end

    def item_title(item_cursor, index)
      collection.item_title_for(item_cursor, fallback: "Item #{index + 1}")
    end

    def draft_path_for(item_cursor)
      params = { path: item_cursor.path.to_s }
      params[:edit_affordance_id] = edit_affordance.id if edit_affordance&.id

      draft_path(draft, params)
    end
  end
end
