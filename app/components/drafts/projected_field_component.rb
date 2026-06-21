# frozen_string_literal: true

module Drafts
  class ProjectedFieldComponent < ApplicationComponent
    attr_reader :draft, :projected_field, :edit_affordance_id

    delegate :cursor, :label, :widget, :help, :placeholder, to: :projected_field

    def initialize(draft:, field:, edit_affordance_id: nil)
      @draft = draft
      @projected_field = field
      @edit_affordance_id = edit_affordance_id
    end

    def input_method
      case input_kind
      when :checkbox
        :check_box
      when :select
        :select
      when :number
        :number_field
      when :textarea
        :text_area
      else
        :text_field
      end
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

    def help_text
      help.presence
    end

    def required?
      cursor.required?
    end

    def show_label?
      label
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
      "flex h-10 w-full rounded border-2 border-black bg-background px-3 py-2 text-sm text-foreground shadow-sm transition-all placeholder:text-muted-foreground focus-visible:outline-hidden focus-visible:shadow-md"
    end

    def textarea_html_class
      "flex min-h-24 w-full rounded border-2 border-black bg-background px-3 py-2 text-sm text-foreground shadow-sm transition-all placeholder:text-muted-foreground focus-visible:outline-hidden focus-visible:shadow-md"
    end

    def input_html_options
      base = {
        id: dom_id,
        data: { action: input_action }
      }

      case input_method
      when :select
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
      when :select
        [ input_name, select_options, {}, input_html_options ]
      when :check_box
        [ input_name, input_html_options, "true", "false" ]
      else
        [ input_name, input_html_options ]
      end
    end

    def input_action
      case input_kind
      when :checkbox, :select
        "change->autosave#submit"
      else
        "input->autosave#queue change->autosave#submit"
      end
    end

    def select_options
      options_for_select(enum_values, field_value)
    end

    private

    def placeholder_options
      placeholder.present? ? { placeholder: placeholder } : {}
    end

    def dom_id_suffix
      sanitized = cursor.ptr.to_s.gsub(/[^a-zA-Z0-9]+/, "_").gsub(/\A_+|_+\z/, "")
      sanitized.present? ? sanitized : "root"
    end
  end
end
