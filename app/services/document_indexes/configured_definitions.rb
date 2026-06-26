# frozen_string_literal: true

module DocumentIndexes
  class ConfiguredDefinitions
    def self.entries_for(document:, revision:)
      new(document:, revision:).entries
    end

    def initialize(document:, revision:)
      @document = document
      @revision = revision
    end

    def entries
      definitions
        .flat_map { |definition| entries_for_definition(definition) }
        .compact
        .uniq { |entry| [ entry.fetch(:index_type), entry[:key], entry.fetch(:value), entry.fetch(:label), entry.fetch(:metadata) ] }
    end

    private

    attr_reader :document, :revision

    def definitions
      schema_wrapper = document.schema_document&.schema_wrapper
      return [] unless schema_wrapper

      schema_wrapper.edit_affordances.includes(edit_document: :head_revision).flat_map do |affordance|
        Array(affordance.body["indexes"])
      end.select { |definition| definition.is_a?(Hash) }
    end

    def entries_for_definition(definition)
      source = definition["source"]
      contexts =
        if source.is_a?(Hash) && source["each"].present?
          Array(value_at(body, source.fetch("ptr", ""))).select { |item| item.is_a?(Hash) }
        else
          [ body ]
        end

      contexts.filter_map do |context|
        next unless condition_matches?(definition["condition"], context)

        build_entry(definition, context)
      end
    end

    def build_entry(definition, context)
      index_type = definition["index_type"].to_s.strip
      key = evaluate(definition["key"], context).to_s.strip
      value = evaluate(definition["value"], context).to_s.strip
      label = evaluate(definition["label"], context).to_s.strip.presence || document_label
      return nil if index_type.blank? || value.blank?

      {
        document: document,
        revision: revision,
        schema_document_id: document.schema_document_id,
        index_type: index_type,
        key: key.presence,
        value: value,
        label: label,
        metadata: metadata_for(definition["metadata"], context)
      }
    end

    def condition_matches?(condition, context)
      return true unless condition.is_a?(Hash)
      return Array(condition["all"]).all? { |nested| condition_matches?(nested, context) } if condition.key?("all")

      actual = evaluate(condition["value"] || condition, context)
      if condition.key?("equals")
        actual.to_s == condition["equals"].to_s
      elsif condition.key?("in")
        Array(condition["in"]).map(&:to_s).include?(actual.to_s)
      else
        true
      end
    end

    def metadata_for(metadata, context)
      return {} unless metadata.is_a?(Hash)

      metadata.each_with_object({}) do |(key, expression), result|
        value = evaluate(expression, context)
        result[key] = value unless value.nil?
      end
    end

    def evaluate(expression, context)
      case expression
      when Hash
        value =
          if expression.key?("root_ptr")
            value_at(body, expression["root_ptr"])
          elsif expression.key?("ptr")
            value_at(context, expression["ptr"])
          elsif expression.key?("literal")
            expression["literal"]
          end
        apply_transform(value, expression["transform"])
      when String
        expression
      else
        expression
      end
    end

    def apply_transform(value, transform)
      return value unless transform.is_a?(Hash)

      if transform["strip_prefix"].present?
        value.to_s.delete_prefix(transform["strip_prefix"].to_s)
      else
        value
      end
    end

    def value_at(source, ptr)
      JsonPtr.get(source, ptr.to_s)
    rescue KeyError, TypeError
      nil
    end

    def body
      @body ||= revision.body
    end

    def document_label
      body["name"].presence || body["title"].presence || document.title.presence || document.key
    end
  end
end
