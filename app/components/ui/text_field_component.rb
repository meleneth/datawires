# frozen_string_literal: true

module Ui
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
      "font-head text-sm font-medium text-foreground"
    end

    def input_classes
      [
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

    def field_name
      form.field_name(name)
    end

    def field_value
      form.object.public_send(name)
    rescue NoMethodError
      nil
    end

    def errors
      form.object.errors[name]
    end

    def error?
      errors.any?
    end
  end
end
