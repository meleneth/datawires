# frozen_string_literal: true

module EditAffordances
  class Collection
    DEFAULT_BEHAVIOR = "list_open"
    DEFAULT_PRESENTATION = "list"
    DEFAULT_CREATION = "new_screen"
    DEFAULT_NAVIGATION = "open_item"
    DEFAULT_POLICY = "disabled"
    DEFAULT_TITLE_BINDING = { "kind" => "property", "name" => "name" }.freeze
    DEFAULT_SUBTITLE_BINDING = { "kind" => "value_label" }.freeze
    CREATION_ALIASES = {
      "append_and_open" => "new_screen"
    }.freeze

    attr_reader :behavior,
                :presentation,
                :creation,
                :navigation,
                :delete_policy,
                :reorder_policy,
                :item_title,
                :item_subtitle,
                :item_screen

    def initialize(config = nil)
      config = {} unless config.is_a?(Hash)

      @behavior = config["behavior"].presence || DEFAULT_BEHAVIOR
      @presentation = config["presentation"].presence || DEFAULT_PRESENTATION
      @creation = normalize_creation(config["creation"].presence || DEFAULT_CREATION)
      @navigation = config["navigation"].presence || DEFAULT_NAVIGATION
      @delete_policy = config["delete"].presence || DEFAULT_POLICY
      @reorder_policy = config["reorder"].presence || DEFAULT_POLICY
      @item_title = config["item_title"].presence || DEFAULT_TITLE_BINDING
      @item_subtitle = config["item_subtitle"].presence || DEFAULT_SUBTITLE_BINDING
      @item_screen = config["item_screen"].presence
    end

    def self.default
      new
    end

    def self.default_config
      {
        "behavior" => DEFAULT_BEHAVIOR,
        "presentation" => DEFAULT_PRESENTATION,
        "creation" => DEFAULT_CREATION,
        "navigation" => DEFAULT_NAVIGATION,
        "delete" => DEFAULT_POLICY,
        "reorder" => DEFAULT_POLICY,
        "item_title" => DEFAULT_TITLE_BINDING,
        "item_subtitle" => DEFAULT_SUBTITLE_BINDING
      }
    end

    def item_title_for(item_cursor, fallback:)
      value_for_binding(item_title, item_cursor).presence || fallback
    end

    def item_subtitle_for(item_cursor)
      value_for_binding(item_subtitle, item_cursor).presence || item_cursor.value_label
    end

    def inline_blank_form?
      creation == "inline_blank_form"
    end

    def delete_enabled?
      delete_policy == "enabled"
    end

    def reorder_enabled?
      reorder_policy == "enabled"
    end

    private

    def normalize_creation(value)
      CREATION_ALIASES.fetch(value, value)
    end

    def value_for_binding(binding, item_cursor)
      return nil unless binding.is_a?(Hash)

      case binding["kind"]
      when "property"
        value = item_cursor.value
        return nil unless value.is_a?(Hash)

        value[binding["name"]]
      when "value_label"
        item_cursor.value_label
      when "reference_label"
        reference_label_for(binding, item_cursor)
      when "none"
        nil
      end
    end

    def reference_label_for(binding, item_cursor)
      value = item_cursor.value
      return nil unless value.is_a?(Hash)

      schema_key = binding["schema_key"].presence || value[binding["schema_key_property"]].to_s.strip.presence
      reference_key = value[binding["key_property"]].to_s.strip
      index_type = binding["index_type"].presence || "identity"
      index_key = binding["index_key"].presence || "document_key"
      return nil if schema_key.blank? || reference_key.blank?

      DocumentIndexEntry
        .joins(:schema_document)
        .where(
          schema_document: {
            domain_id: item_cursor.source.document.domain_id,
            key: schema_key
          }
        )
        .where(index_type: index_type, key: index_key, value: reference_key)
        .pick(:label)
        .presence || reference_key
    end
  end
end
