# frozen_string_literal: true

require "json"

module RetroUI
  module Rails
    class ChartComponent < ViewComponent::Base
      include RetroUI::Rails::ClassNames

      BASE_CLASSES = "relative w-full rounded border-2 border-black bg-card p-4 text-card-foreground shadow-md"
      SVG_CLASSES = "block w-full overflow-visible"

      attr_reader :data, :height, :title, :description

      def initialize(data:, height: 300, title: nil, description: nil, x_key: :name, y_key: :value, label_key: :name, value_key: :value, html_options: {})
        @data = Array(data)
        @height = Integer(height)
        @title = title
        @description = description
        @x_key = x_key.to_s
        @y_key = y_key.to_s
        @label_key = label_key.to_s
        @value_key = value_key.to_s
        @html_options = html_options.dup
      end

      def component_options
        options = @html_options.dup
        caller_classes = options.delete(:class) || options.delete("class")
        data_attrs = (options.delete(:data) || options.delete("data") || {}).dup

        data_attrs[:controller] = class_names(data_attrs[:controller], "retro-ui--chart")
        data_attrs[:"retro-ui--chart-type-value"] = chart_type
        data_attrs[:"retro-ui--chart-data-value"] = JSON.generate(normalized_data)
        data_attrs[:"retro-ui--chart-x-key-value"] = @x_key
        data_attrs[:"retro-ui--chart-y-key-value"] = @y_key
        data_attrs[:"retro-ui--chart-label-key-value"] = @label_key
        data_attrs[:"retro-ui--chart-value-key-value"] = @value_key

        options[:class] = class_names(BASE_CLASSES, caller_classes)
        options[:data] = data_attrs
        options
      end

      def svg_options
        {
          class: SVG_CLASSES,
          role: "img",
          height: height,
          viewBox: "0 0 640 #{height}",
          preserveAspectRatio: "xMidYMid meet",
          data: { "retro-ui--chart-target": "svg" },
          aria: { label: accessible_label }
        }
      end

      def fallback_options
        {
          class: "sr-only",
          data: { "retro-ui--chart-target": "fallback" }
        }
      end

      def chart_type
        raise NotImplementedError, "#{self.class.name} must implement #chart_type"
      end

      private

      def accessible_label
        title || "#{chart_type.tr("-", " ")} chart"
      end

      def normalized_data
        data.map do |item|
          item.respond_to?(:to_h) ? item.to_h.transform_keys(&:to_s) : item
        end
      end
    end
  end
end
