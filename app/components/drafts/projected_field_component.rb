# frozen_string_literal: true

module Drafts
  class ProjectedFieldComponent < ApplicationComponent
    attr_reader :draft, :projected_field

    delegate :cursor, :label, :widget, to: :projected_field

    def initialize(draft:, field:)
      @draft = draft
      @projected_field = field
    end

    def input_kind
      return widget.to_sym unless widget == "auto"

      cursor.input_kind
    end

    def dom_id
      @dom_id ||= "field_#{dom_id_suffix}"
    end

    def input_name
      :value
    end

    def label_text
      cursor.name.to_s.humanize
    end

    def show_label?
      label
    end

    def patch_path
      patch_ptr_draft_path(draft)
    end

    def ptr
      cursor.ptr
    end

    def path
      cursor.path.to_s
    end

    def field_value
      cursor.field_value
    end

    def checkbox_value
      cursor.checkbox_value
    end

    def enum_values
      cursor.enum_values
    end

    def input_html_class
      "w-full rounded-lg border border-ls5-violet-2"
    end

    def select_options
      options_for_select(enum_values, field_value)
    end

    private

    def dom_id_suffix
      sanitized = cursor.ptr.to_s.gsub(/[^a-zA-Z0-9]+/, "_").gsub(/\A_+|_+\z/, "")
      sanitized.present? ? sanitized : "root"
    end
  end
end
