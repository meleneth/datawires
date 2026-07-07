# frozen_string_literal: true

module ViewAffordances
  class MudChoicePlayerProjection
    DEFAULT_CHOICE_ROOM_SCHEMA_KEY = "mud-choice-room"
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
        renderer: "mud_choice_player",
        title: config["title"].presence || view_affordance.title,
        data: {
          "room" => room_data,
          "choices" => choices
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
        "room_type" => body["room_type"].presence || "challenge",
        "prompt" => body["prompt"].to_s,
        "stage" => body["stage"].to_s,
        "terminal_text" => body["terminal_text"].to_s
      }
    end

    def missing_room_data
      {
        "key" => current_room_key.to_s,
        "title" => "Unknown choice room",
        "room_type" => "death",
        "prompt" => "No choice room document exists for #{current_room_key.presence || 'the configured start room'}.",
        "stage" => "",
        "terminal_text" => ""
      }
    end

    def choices
      Array(current_room&.body&.fetch("choices", [])).first(3).filter_map.with_index(1) do |choice_body, index|
        next unless choice_body.is_a?(Hash)

        destination_key = choice_body["target_room_key"].to_s.strip
        destination = choice_rooms_by_key[destination_key]
        {
          "position" => index,
          "label" => choice_body["label"].presence || "Choice #{index}",
          "description" => choice_body["description"].to_s,
          "outcome" => choice_body["outcome"].presence || "death",
          "target_room_key" => destination_key,
          "target_room_title" => destination_label(destination, destination_key),
          "url" => destination_url(destination)
        }
      end
    end

    def destination_label(destination, destination_key)
      return destination_key if destination.blank?

      destination.body["name"].presence || destination.title.presence || destination.key
    end

    def destination_url(destination)
      return nil unless destination && choice_view_affordance

      document_view_affordance_path(destination, choice_view_affordance)
    end

    def current_room
      @current_room ||= choice_rooms_by_key[current_room_key]
    end

    def current_room_key
      @current_room_key ||= begin
        if document.schema_document&.key == choice_room_schema_key
          document.key
        else
          config["start_room_key"].to_s.strip
        end
      end
    end

    def choice_view_affordance
      @choice_view_affordance ||= choice_room_schema&.schema_wrapper&.view_affordances&.find_by(title: view_affordance.title) ||
        choice_room_schema&.schema_wrapper&.view_affordances&.order(:title)&.first
    end

    def choice_rooms_by_key
      @choice_rooms_by_key ||= documents_for_schema(choice_room_schema_key).index_by(&:key)
    end

    def documents_for_schema(schema_key)
      schema = document.domain.documents.find_by(key: schema_key)
      return Document.none unless schema

      document.domain.documents
        .includes(:head_revision)
        .with_head
        .where(schema_document: schema)
    end

    def choice_room_schema
      @choice_room_schema ||= document.domain.documents.find_by(key: choice_room_schema_key)
    end

    def choice_room_schema_key
      config["choice_room_schema_key"].presence || DEFAULT_CHOICE_ROOM_SCHEMA_KEY
    end

    def config
      @config ||= view_affordance.body.fetch("config", {})
    end
  end
end
