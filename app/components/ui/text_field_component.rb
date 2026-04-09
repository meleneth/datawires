module Ui
  # app/components/text_field_component.rb
  # frozen_string_literal: true

  class TextFieldComponent < ViewComponent::Base
    def initialize(form:, name:, id: nil, label: nil, placeholder: nil, html_options: {})
      @form = form
      @name = name
      @id = id || default_id
      @label = label || name.to_s.humanize
      @placeholder = placeholder
      @html_options = html_options
    end

    private

    attr_reader :form, :name, :id, :label, :placeholder, :html_options

    def default_id
      "#{form.object_name}_#{name}"
    end

    def label_classes
      "block text-sm font-medium text-ink"
    end

    def input_classes
      [
        "w-full rounded-md border border-ls5-violet-3 bg-white px-3 py-2 text-ink",
        "placeholder:text-ls5-violet-5",
        "focus:outline-none focus:ring-2 focus:ring-ls5-blue-3 focus:border-ls5-blue-4",
        html_options[:class]
      ].compact.join(" ")
    end

    def merged_html_options
      html_options.merge(
        id: id,
        placeholder: placeholder,
        class: input_classes
      )
    end

    def errors
      form.object.errors[name]
    end

    def error?
      errors.any?
    end
  end
end
