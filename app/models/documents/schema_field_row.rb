module Documents
  # frozen_string_literal: true

  class SchemaFieldRow
    def initialize(draft:, ptr:, field_value:, schema_node:, name:)
      @draft = draft
      @ptr = ptr
      @field_value = field_value
      @schema_node = schema_node || {}
      @name = name
    end

    attr_reader :draft, :ptr, :field_value, :schema_node, :name

    def enum_values
      Array(schema_node["enum"]).presence
    end

    def input_kind
      return :select if enum_values.present?

      case schema_node["type"]
      when "boolean"
        :checkbox
      when "integer", "number"
        :number
      else
        :text
      end
    end

    def checkbox_value
      ActiveModel::Type::Boolean.new.cast(field_value)
    end
  end
end
