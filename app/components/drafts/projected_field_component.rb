# frozen_string_literal: true

module Drafts
  class ProjectedFieldComponent < ApplicationComponent
    attr_reader :draft, :projected_field, :edit_affordance_id

    delegate :cursor, :label, :widget, :help, :placeholder, :display, :reference, to: :projected_field

    def initialize(draft:, field:, edit_affordance_id: nil)
      @draft = draft
      @projected_field = field
      @edit_affordance_id = edit_affordance_id
    end

    def input_method
      case input_kind
      when :checkbox
        :check_box
      when :select, :reference
        :select
      when :number
        :number_field
      when :textarea, :base64_image
        :text_area
      else
        :text_field
      end
    end

    def input_kind
      return widget.to_sym unless widget == "auto"

      projected_field.inferred_widget.to_sym
    end

    def dom_id
      @dom_id ||= "field_#{dom_id_suffix}"
    end

    def input_name
      :value
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

    def show_label?
      label
    end

    def compact?
      display_option_enabled?("compact")
    end

    def readonly?
      display_option_enabled?("readonly")
    end

    def base64_image?
      input_kind == :base64_image
    end

    def reference?
      input_kind == :reference
    end

    def wrapper_class
      compact? ? "space-y-0.5" : "space-y-1"
    end

    def value_preview
      return "Blank" unless cursor.present?

      cursor.value_label
    end

    def base64_image_src
      value = field_value.to_s.strip
      return nil if value.blank?
      return value if value.match?(/\Adata:image\/(?:png|jpe?g|gif|webp);base64,/i)

      "data:image/png;base64,#{value.delete("\r\n\t ")}"
    end

    def patch_path
      patch_ptr_draft_path(draft)
    end

    def form_data_attributes
      {
        controller: "autosave",
        autosave_delay_value: 400
      }
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
      cx(
        "flex w-full rounded border-2 border-black bg-background text-sm text-foreground shadow-sm transition-all placeholder:text-muted-foreground focus-visible:outline-hidden focus-visible:shadow-md",
        compact? ? "h-8 px-2 py-1" : "h-10 px-3 py-2"
      )
    end

    def textarea_html_class
      cx(
        "flex w-full rounded border-2 border-black bg-background text-sm text-foreground shadow-sm transition-all placeholder:text-muted-foreground focus-visible:outline-hidden focus-visible:shadow-md",
        compact? ? "min-h-16 px-2 py-1" : "min-h-24 px-3 py-2"
      )
    end

    def input_html_options
      base = {
        id: dom_id,
        data: { action: input_action }
      }

      case input_method
      when :select, :reference
        base.merge(class: input_html_class)
      when :number_field, :text_field
        base.merge(class: input_html_class, value: field_value).merge(placeholder_options)
      when :text_area
        base.merge(class: textarea_html_class, value: field_value).merge(placeholder_options)
      when :check_box
        base.merge(checked: checkbox_value)
      else
        base
      end
    end

    def input_leading_args
      case input_method
      when :select, :reference
        [ input_name, select_options, {}, input_html_options ]
      when :check_box
        [ input_name, input_html_options, "true", "false" ]
      else
        [ input_name, input_html_options ]
      end
    end

    def input_action
      case input_kind
      when :checkbox, :select, :reference
        "change->autosave#submit"
      else
        "input->autosave#queue change->autosave#submit"
      end
    end

    def select_options
      return options_for_select(reference_options, field_value) if reference?

      options_for_select(enum_values, field_value)
    end

    private

    def placeholder_options
      placeholder.present? ? { placeholder: placeholder } : {}
    end

    def display_option_enabled?(key)
      display.is_a?(Hash) && display[key] == true
    end

    def reference_options
      options = reference_entries.map { |entry| [ entry.label.presence || entry.value, entry.value ] }
      placeholder = reference["placeholder"].presence || "Select reference"
      [ [ placeholder, "" ] ] + options
    end

    def reference_entries
      schema_key = reference["schema_key"].presence
      index_type = reference["index_type"].presence || "identity"
      return DocumentIndexEntry.none unless schema_key

      DocumentIndexEntry
        .joins(:schema_document)
        .where(schema_document: { domain_id: draft.document.domain_id, key: schema_key })
        .where(index_type: index_type)
        .order(:label, :value)
    end

    def dom_id_suffix
      sanitized = cursor.ptr.to_s.gsub(/[^a-zA-Z0-9]+/, "_").gsub(/\A_+|_+\z/, "")
      sanitized.present? ? sanitized : "root"
    end
  end
end
