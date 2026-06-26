# frozen_string_literal: true

module Clusters
  module Catalog
    module_function

    WORLD_BUILDING = "worldbuilding"

    def options
      [
        [ "Blank", "" ],
        [ "Worldbuilding tools", WORLD_BUILDING ]
      ]
    end

    def include?(key)
      key.blank? || key == WORLD_BUILDING
    end

    def definition_for(key)
      return nil if key.blank?
      return worldbuilding if key == WORLD_BUILDING

      raise ArgumentError, "unknown cluster: #{key}"
    end

    def worldbuilding
      {
        key: WORLD_BUILDING,
        name: "Worldbuilding tools",
        schemas: [
          person_schema,
          place_schema,
          thing_schema,
          party_schema,
          timeline_event_schema
        ]
      }
    end

    def person_schema
      schema(
        key: "person",
        title: "Person",
        required: %w[name],
        properties: {
          "name" => string("Name"),
          "summary" => string("Summary"),
          "origin" => string("Origin"),
          "notes" => string("Notes")
        },
        rows: [
          [ field("/name", span: 6), field("/origin", span: 6) ],
          [ field("/summary", span: 12, widget: "textarea") ],
          [ field("/notes", span: 12, widget: "textarea") ],
          [ commit(span: 12) ]
        ]
      )
    end

    def place_schema
      schema(
        key: "place",
        title: "Place",
        required: %w[name],
        properties: {
          "name" => string("Name"),
          "kind" => string("Kind"),
          "summary" => string("Summary"),
          "notes" => string("Notes")
        },
        rows: [
          [ field("/name", span: 6), field("/kind", span: 6) ],
          [ field("/summary", span: 12, widget: "textarea") ],
          [ field("/notes", span: 12, widget: "textarea") ],
          [ commit(span: 12) ]
        ]
      )
    end

    def thing_schema
      schema(
        key: "thing",
        title: "Thing",
        required: %w[name],
        properties: {
          "name" => string("Name"),
          "kind" => string("Kind"),
          "summary" => string("Summary"),
          "notes" => string("Notes")
        },
        rows: [
          [ field("/name", span: 6), field("/kind", span: 6) ],
          [ field("/summary", span: 12, widget: "textarea") ],
          [ field("/notes", span: 12, widget: "textarea") ],
          [ commit(span: 12) ]
        ]
      )
    end

    def party_schema
      schema(
        key: "party",
        title: "Party",
        required: %w[name],
        properties: {
          "name" => string("Name"),
          "summary" => string("Summary"),
          "members" => {
            "type" => "array",
            "title" => "Current members",
            "default" => [],
            "items" => {
              "type" => "object",
              "required" => %w[person_key],
              "properties" => {
                "person_key" => string("Person key"),
                "role" => string("Role"),
                "notes" => string("Notes")
              },
              "additionalProperties" => false
            }
          },
          "notes" => string("Notes")
        },
        rows: [
          [ field("/name", span: 6), field("/summary", span: 6, widget: "textarea") ],
          [
            array_field(
              "/members",
              span: 12,
              item_title: property_binding("person_key"),
              item_subtitle: property_binding("role")
            )
          ],
          [ field("/notes", span: 12, widget: "textarea") ],
          [ commit(span: 12) ]
        ]
      )
    end

    def timeline_event_schema
      schema(
        key: "timeline-event",
        title: "Timeline Event",
        required: %w[relative_time title event_type],
        properties: {
          "relative_time" => {
            "type" => "integer",
            "title" => "Relative time",
            "description" => "Relative timestamp. Negative values are allowed."
          },
          "title" => string("Title"),
          "event_type" => {
            "type" => "string",
            "title" => "Event type",
            "enum" => %w[general person place thing party_join party_leave]
          },
          "summary" => string("Summary"),
          "participants" => {
            "type" => "array",
            "title" => "Participants",
            "default" => [],
            "items" => participant_schema
          },
          "party_key" => string("Party key"),
          "person_key" => string("Person key"),
          "notes" => string("Notes")
        },
        rows: [
          [ field("/relative_time", span: 3, widget: "number"), field("/event_type", span: 3), field("/title", span: 6) ],
          [ field("/summary", span: 12, widget: "textarea") ],
          [
            array_field(
              "/participants",
              span: 12,
              item_title: property_binding("key"),
              item_subtitle: property_binding("kind")
            )
          ],
          [ field("/party_key", span: 6, help: "For party_join and party_leave events."), field("/person_key", span: 6, help: "For party_join and party_leave events.") ],
          [ field("/notes", span: 12, widget: "textarea") ],
          [ commit(span: 12) ]
        ]
      )
    end

    def schema(key:, title:, required:, properties:, rows:)
      {
        key: key,
        title: title,
        body: {
          "$schema" => Document::JSON_SCHEMA_2020_12,
          "$id" => "datawires:clusters/worldbuilding/#{key}",
          "title" => title,
          "type" => "object",
          "required" => required,
          "properties" => properties,
          "additionalProperties" => false
        },
        affordance: {
          "version" => 1,
          "start_screen" => "main",
          "commit_mode" => "review_screen",
          "screens" => [
            {
              "id" => "main",
              "title" => title,
              "columns" => 12,
              "default_span" => 6,
              "width" => "large",
              "rows" => rows
            }
          ],
          "subforms" => []
        }
      }
    end

    def participant_schema
      {
        "type" => "object",
        "required" => %w[kind key],
        "properties" => {
          "kind" => {
            "type" => "string",
            "title" => "Kind",
            "enum" => %w[person place thing party]
          },
          "key" => string("Document key"),
          "role" => string("Role"),
          "notes" => string("Notes")
        },
        "additionalProperties" => false
      }
    end

    def string(title)
      {
        "type" => "string",
        "title" => title
      }
    end

    def field(ptr, span:, widget: "auto", help: nil)
      {
        "binding" => {
          "kind" => "document_ptr",
          "ptr" => ptr
        },
        "span" => span,
        "widget" => widget
      }.tap do |cell|
        cell["help"] = help if help.present?
      end
    end

    def array_field(ptr, span:, item_title:, item_subtitle:)
      field(ptr, span: span, widget: "array").merge(
        "collection" => {
          "behavior" => "list_open",
          "presentation" => "cards",
          "creation" => "inline_blank_form",
          "navigation" => "open_item",
          "delete" => "enabled",
          "reorder" => "enabled",
          "item_title" => item_title,
          "item_subtitle" => item_subtitle
        }
      )
    end

    def property_binding(name)
      {
        "kind" => "property",
        "name" => name
      }
    end

    def commit(span:)
      {
        "kind" => "commit",
        "span" => span,
        "message_mode" => "inline_optional"
      }
    end
  end
end
