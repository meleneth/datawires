# frozen_string_literal: true

module ViewAffordances
  class MudPlayerProjection
    DEFAULT_ROOM_SCHEMA_KEY = "mud-room"
    DEFAULT_CHARACTER_SCHEMA_KEY = "mud-character"
    DEFAULT_ITEM_SCHEMA_KEY = "mud-item"
    include Rails.application.routes.url_helpers

    def self.call(document:, view_affordance:)
      new(document:, view_affordance:).call
    end

    def initialize(document:, view_affordance:)
      @document = document
      @view_affordance = view_affordance
    end

    def call
      Projection.new(
        renderer: "mud_player",
        title: config["title"].presence || view_affordance.title,
        data: {
          "room" => room_data,
          "exits" => exits,
          "characters" => characters,
          "items" => items,
          "player" => player_data
        }
      )
    end

    private

    attr_reader :document, :view_affordance

    def room_data
      return missing_room_data unless current_room

      body = current_room.body
      {
        "key" => current_room.key,
        "title" => body["name"].presence || current_room.title.presence || current_room.key,
        "description" => body["description"].to_s,
        "notes" => body["notes"].to_s
      }
    end

    def missing_room_data
      {
        "key" => current_room_key.to_s,
        "title" => "Unknown room",
        "description" => "No room document exists for #{current_room_key.presence || 'the configured start room'}.",
        "notes" => ""
      }
    end

    def exits
      Array(current_room&.body&.fetch("exits", [])).filter_map do |exit_body|
        next unless exit_body.is_a?(Hash)

        destination_key = exit_body["room_key"].to_s.strip
        next if destination_key.blank?

        destination = room_documents_by_key[destination_key]
        {
          "direction" => exit_body["direction"].to_s,
          "label" => exit_body["label"].presence || exit_body["direction"].to_s,
          "room_key" => destination_key,
          "room_title" => destination_label(destination, destination_key),
          "description" => exit_body["description"].to_s,
          "url" => destination_url(destination)
        }
      end
    end

    def characters
      documents_for_schema(character_schema_key).filter_map do |character|
        body = character.body
        next unless body["location_room_key"].to_s.strip == current_room&.key
        next if character.id == document.id

        {
          "key" => character.key,
          "name" => body["name"].presence || character.title.presence || character.key,
          "description" => body["description"].to_s,
          "disposition" => body["disposition"].to_s
        }
      end.sort_by { |character| character.fetch("name") }
    end

    def items
      documents_for_schema(item_schema_key).filter_map do |item|
        body = item.body
        next unless body["location_kind"].to_s == "room"
        next unless body["location_key"].to_s.strip == current_room&.key

        {
          "key" => item.key,
          "name" => body["name"].presence || item.title.presence || item.key,
          "description" => body["description"].to_s,
          "portable" => body["portable"] == true
        }
      end.sort_by { |item| item.fetch("name") }
    end

    def player_data
      return nil unless document.schema_document&.key == character_schema_key

      body = document.body
      {
        "key" => document.key,
        "name" => body["name"].presence || document.title.presence || document.key,
        "inventory" => inventory_items
      }
    end

    def inventory_items
      item_keys = Array(document.body["inventory_item_keys"]).map { |key| key.to_s.strip }.reject(&:blank?)
      item_keys.filter_map do |item_key|
        item = item_documents_by_key[item_key]
        next unless item

        {
          "key" => item.key,
          "name" => item.body["name"].presence || item.title.presence || item.key,
          "description" => item.body["description"].to_s
        }
      end
    end

    def destination_label(destination, destination_key)
      return destination_key unless destination

      destination.body["name"].presence || destination.title.presence || destination.key
    end

    def destination_url(destination)
      return nil unless destination && room_view_affordance

      document_view_affordance_path(destination, room_view_affordance)
    end

    def current_room
      @current_room ||= room_documents_by_key[current_room_key]
    end

    def current_room_key
      @current_room_key ||= begin
        if document.schema_document&.key == room_schema_key
          document.key
        elsif document.body["location_room_key"].present?
          document.body["location_room_key"].to_s.strip
        elsif document.body["start_room_key"].present?
          document.body["start_room_key"].to_s.strip
        else
          config["start_room_key"].to_s.strip
        end
      end
    end

    def room_view_affordance
      @room_view_affordance ||= room_schema&.schema_wrapper&.view_affordances&.find_by(title: view_affordance.title) ||
        room_schema&.schema_wrapper&.view_affordances&.order(:title)&.first
    end

    def room_documents_by_key
      @room_documents_by_key ||= documents_for_schema(room_schema_key).index_by(&:key)
    end

    def item_documents_by_key
      @item_documents_by_key ||= documents_for_schema(item_schema_key).index_by(&:key)
    end

    def documents_for_schema(schema_key)
      schema = document.domain.documents.find_by(key: schema_key)
      return Document.none unless schema

      document.domain.documents
        .includes(:head_revision)
        .with_head
        .where(schema_document: schema)
    end

    def room_schema
      @room_schema ||= document.domain.documents.find_by(key: room_schema_key)
    end

    def room_schema_key
      config["room_schema_key"].presence || DEFAULT_ROOM_SCHEMA_KEY
    end

    def character_schema_key
      config["character_schema_key"].presence || DEFAULT_CHARACTER_SCHEMA_KEY
    end

    def item_schema_key
      config["item_schema_key"].presence || DEFAULT_ITEM_SCHEMA_KEY
    end

    def config
      @config ||= view_affordance.body.fetch("config", {})
    end
  end
end
