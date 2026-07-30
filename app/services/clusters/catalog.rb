# frozen_string_literal: true

module Clusters
  module Catalog
    module_function

    WORLD_BUILDING = "worldbuilding"
    ROBERTS_RULES = "roberts-rules"
    PRIVATE_MUD = "private-mud"

    def options
      [
        [ "Blank", "" ],
        [ "Worldbuilding tools", WORLD_BUILDING ],
        [ "Robert's Rules of Order", ROBERTS_RULES ],
        [ "Private MUD authoring", PRIVATE_MUD ]
      ]
    end

    def include?(key)
      key.blank? || key == WORLD_BUILDING || key == ROBERTS_RULES || key == PRIVATE_MUD
    end

    def definition_for(key)
      return nil if key.blank?
      return worldbuilding if key == WORLD_BUILDING
      return roberts_rules if key == ROBERTS_RULES
      return private_mud if key == PRIVATE_MUD

      raise ArgumentError, "unknown cluster: #{key}"
    end

    def private_mud
      {
        key: PRIVATE_MUD,
        name: "Private MUD authoring",
        repository_mode: false,
        home: {
          "title" => "Private MUD Home",
          "groups" => [
            {
              "title" => "Author",
              "links" => [
                schema_home_link("Rooms", "Places players can enter and connect with exits.", schema_key: "mud-room"),
                schema_home_link("Characters", "Player and non-player characters.", schema_key: "mud-character"),
                schema_home_link("Items", "Objects placed in rooms or carried by characters.", schema_key: "mud-item"),
                schema_home_link("Worlds", "Entry points and play settings.", schema_key: "mud-world"),
                schema_home_link("Choice Rooms", "Three-choice PBX-style challenge rooms.", schema_key: "mud-choice-room")
              ]
            }
          ]
        },
        schemas: [
          domain_home_page_schema(cluster_key: PRIVATE_MUD),
          mud_room_schema,
          mud_character_schema,
          mud_item_schema,
          mud_world_schema,
          mud_choice_room_schema
        ]
      }
    end

    def worldbuilding
      {
        key: WORLD_BUILDING,
        name: "Worldbuilding tools",
        repository_mode: false,
        home: {
          "title" => "Worldbuilding Home",
          "groups" => [
            {
              "title" => "Schemas",
              "links" => [
                schema_home_link("Workspace", "Open the Worldbuilder Board.", schema_key: "domain-home-page"),
                schema_home_link("People", "Characters and other people.", schema_key: "person"),
                schema_home_link("Places", "Locations in the world.", schema_key: "place"),
                schema_home_link("Things", "Objects, artifacts, and concepts.", schema_key: "thing"),
                schema_home_link("Parties", "Groups and memberships.", schema_key: "party"),
                schema_home_link("Timeline Events", "Relative-time story facts.", schema_key: "timeline-event")
              ]
            }
          ]
        },
        schemas: [
          domain_home_page_schema,
          person_schema,
          place_schema,
          thing_schema,
          party_schema,
          timeline_event_schema,
          registered_schema(Boards::Schema)
        ],
        boards: [
          {
            schema_key: "domain-home-page",
            document_key: "worldbuilder-board",
            title: "Worldbuilder Board",
            default: true,
            body: Boards::Definitions.worldbuilder_workspace
          }
        ]
      }
    end

    def roberts_rules
      {
        key: ROBERTS_RULES,
        name: "Robert's Rules of Order",
        repository_mode: true,
        home: {
          "title" => "Datawires Parliamentary Workspace",
          "groups" => [
            {
              "title" => "Domain schemas",
              "links" => [
                schema_home_link("Bodies", "Organizations that conduct business.", schema_key: Bodies::Schema::KEY),
                schema_home_link("Meetings", "Scheduled meeting documents.", schema_key: Meetings::Schema::KEY),
                schema_home_link("Proposals", "Business submitted before or outside a meeting.", schema_key: Proposals::Schema::KEY),
                schema_home_link("Decisions", "Durable procedural dispositions.", schema_key: Decisions::Schema::KEY),
                schema_home_link("Agreements", "Authoritative documents produced by adoption.", schema_key: Agreements::Schema::KEY)
              ]
            },
            {
              "title" => "Repository",
              "links" => [
                {
                  "kind" => "repository_history",
                  "title" => "Repository History",
                  "description" => "Global commits, parent hashes, document revisions, and current HEAD."
                }
              ]
            }
          ]
        },
        schemas: [
          domain_home_page_schema(cluster_key: ROBERTS_RULES),
          registered_schema(Bodies::Schema),
          registered_schema(Meetings::Schema),
          registered_schema(Proposals::Schema),
          registered_schema(Decisions::Schema),
          registered_schema(Agreements::Schema),
          registered_schema(ProceduralPolicies::Schema),
          registered_schema(Boards::Schema)
        ],
        boards: [
          {
            schema_key: Bodies::Schema::KEY,
            document_key: "body-board",
            title: "Datawires Board",
            default: true,
            body: Boards::Definitions.body_workspace
          },
          {
            schema_key: Bodies::Schema::KEY,
            document_key: "body-administration-board",
            title: "Body Administration",
            body: Boards::Definitions.body_administration
          }
        ]
      }
    end

    def domain_home_page_schema(cluster_key: WORLD_BUILDING)
      schema(
        cluster_key: cluster_key,
        key: "domain-home-page",
        title: "Domain Home Page",
        required: %w[title groups],
        properties: {
          "title" => string("Title"),
          "groups" => {
            "type" => "array",
            "title" => "Groups",
            "default" => [],
            "items" => {
              "type" => "object",
              "required" => %w[title links],
              "properties" => {
                "title" => string("Group title"),
                "links" => {
                  "type" => "array",
                  "title" => "Links",
                  "default" => [],
                  "items" => {
                    "type" => "object",
                    "required" => %w[kind title],
                    "properties" => {
                      "kind" => enum_string("Kind", %w[domain schema document view]),
                      "title" => string("Title"),
                      "description" => string("Description"),
                      "schema_key" => string("Schema key"),
                      "document_key" => string("Document key"),
                      "view_title" => string("View title")
                    },
                    "additionalProperties" => false
                  }
                }
              },
              "additionalProperties" => false
            }
          }
        },
        rows: [
          [ field("/title", span: 12) ],
          [
            array_field(
              "/groups",
              span: 12,
              item_title: property_binding("title"),
              item_subtitle: property_binding("title"),
              item_rows: [
                [ field("/title", span: 12) ],
                [
                  array_field(
                    "/links",
                    span: 12,
                    item_title: property_binding("title"),
                    item_subtitle: property_binding("kind"),
                    item_rows: [
                      [ field("/kind", span: 3), field("/title", span: 3), field("/schema_key", span: 3), field("/document_key", span: 3) ],
                      [ field("/view_title", span: 4), field("/description", span: 8, widget: "textarea") ]
                    ]
                  )
                ]
              ]
            )
          ],
          [ commit(span: 12, commit_mode: "immediate", message_mode: "inline_optional") ]
        ]
      )
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
        ],
        view_affordances: [
          timeline_view_affordance(
            key: "person-participation-timeline-view-affordance",
            title: "Person participation timeline view affordance",
            affordance_title: "Timeline",
            schema_key: "timeline-event",
            relative_time_label: "Relative time",
            participant_kind: "person"
          )
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
              item_subtitle: property_binding("role"),
              item_rows: [
                [
                  reference_field("/person_key", span: 6, schema_key: "person", placeholder: "Select person"),
                  field("/role", span: 6)
                ],
                [ field("/notes", span: 12, widget: "textarea") ]
              ]
            )
          ],
          [ field("/notes", span: 12, widget: "textarea") ],
          [ commit(span: 12) ]
        ],
        index_definitions: [
          array_index_definition(
            index_type: "party_member",
            source_ptr: "/members",
            key: literal_expression("person"),
            value: ptr_expression("/person_key"),
            label: ptr_expression("/role"),
            metadata: {
              "role" => ptr_expression("/role"),
              "notes" => ptr_expression("/notes")
            }
          )
        ],
        view_affordances: [
          timeline_view_affordance(
            key: "party-participation-timeline-view-affordance",
            title: "Party participation timeline view affordance",
            affordance_title: "Timeline",
            schema_key: "timeline-event",
            relative_time_label: "Relative time",
            participant_kind: "party"
          )
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
              item_title: reference_label_binding(schema_key_property: "kind", key_property: "key"),
              item_subtitle: property_binding("notes"),
              item_rows: [
                [
                  field("/kind", span: 6),
                  dynamic_reference_field("/key", span: 6, schema_key_from: "/kind", placeholder: "Select participant")
                ],
                [ field("/role", span: 6), field("/notes", span: 6, widget: "textarea") ]
              ]
            )
          ],
          [
            reference_field("/party_key", span: 6, schema_key: "party", placeholder: "Select party", help: "For party_join and party_leave events."),
            reference_field("/person_key", span: 6, schema_key: "person", placeholder: "Select person", help: "For party_join and party_leave events.")
          ],
          [ field("/notes", span: 12, widget: "textarea") ],
          [ commit(span: 12, commit_mode: "immediate", message_mode: "inline_optional") ]
        ],
        index_definitions: timeline_event_index_definitions,
        view_affordances: [
          timeline_view_affordance(
            key: "timeline-event-timeline-view-affordance",
            title: "Timeline Event timeline view affordance",
            affordance_title: "Timeline",
            schema_key: "timeline-event",
            relative_time_label: "Relative time"
          )
        ]
      )
    end

    def mud_room_schema
      schema(
        cluster_key: PRIVATE_MUD,
        key: "mud-room",
        title: "MUD Room",
        required: %w[name description],
        properties: {
          "name" => string("Name"),
          "description" => string("Description"),
          "zone" => string("Zone"),
          "exits" => {
            "type" => "array",
            "title" => "Exits",
            "default" => [],
            "items" => {
              "type" => "object",
              "required" => %w[direction room_key],
              "properties" => {
                "direction" => enum_string("Direction", %w[north northeast east southeast south southwest west northwest up down in out]),
                "label" => string("Label"),
                "room_key" => string("Destination room"),
                "description" => string("Description")
              },
              "additionalProperties" => false
            }
          },
          "notes" => string("Author notes")
        },
        rows: [
          [ field("/name", span: 6), field("/zone", span: 6) ],
          [ field("/description", span: 12, widget: "textarea") ],
          [
            array_field(
              "/exits",
              span: 12,
              item_title: property_binding("direction"),
              item_subtitle: reference_label_binding(schema_key_property: nil, key_property: "room_key", fixed_schema_key: "mud-room"),
              item_rows: [
                [
                  field("/direction", span: 3),
                  field("/label", span: 3),
                  reference_field("/room_key", span: 6, schema_key: "mud-room", placeholder: "Select room")
                ],
                [ field("/description", span: 12, widget: "textarea") ]
              ]
            )
          ],
          [ field("/notes", span: 12, widget: "textarea") ],
          [ commit(span: 12, commit_mode: "immediate", message_mode: "inline_optional") ]
        ],
        view_affordances: [
          mud_player_view_affordance(
            key: "mud-room-play-view-affordance",
            title: "MUD room play view affordance",
            start_room_key: nil
          )
        ]
      )
    end

    def mud_character_schema
      schema(
        cluster_key: PRIVATE_MUD,
        key: "mud-character",
        title: "MUD Character",
        required: %w[name location_room_key],
        properties: {
          "name" => string("Name"),
          "character_type" => enum_string("Character type", %w[player npc]),
          "description" => string("Description"),
          "disposition" => string("Disposition"),
          "location_room_key" => string("Current room"),
          "inventory_item_keys" => {
            "type" => "array",
            "title" => "Inventory items",
            "default" => [],
            "items" => string("Item key")
          },
          "notes" => string("Author notes")
        },
        rows: [
          [ field("/name", span: 4), field("/character_type", span: 4), reference_field("/location_room_key", span: 4, schema_key: "mud-room", placeholder: "Select room") ],
          [ field("/description", span: 12, widget: "textarea") ],
          [ field("/disposition", span: 6), field("/notes", span: 6, widget: "textarea") ],
          [
            array_field(
              "/inventory_item_keys",
              span: 12,
              item_title: value_label_binding,
              item_subtitle: none_binding
            )
          ],
          [ commit(span: 12, commit_mode: "immediate", message_mode: "inline_optional") ]
        ],
        view_affordances: [
          mud_player_view_affordance(
            key: "mud-character-play-view-affordance",
            title: "MUD character play view affordance",
            start_room_key: nil
          )
        ]
      )
    end

    def mud_item_schema
      schema(
        cluster_key: PRIVATE_MUD,
        key: "mud-item",
        title: "MUD Item",
        required: %w[name location_kind location_key],
        properties: {
          "name" => string("Name"),
          "item_type" => string("Item type"),
          "description" => string("Description"),
          "portable" => {
            "type" => "boolean",
            "title" => "Portable",
            "default" => true
          },
          "location_kind" => enum_string("Location kind", %w[room character hidden]),
          "location_key" => string("Location key"),
          "notes" => string("Author notes")
        },
        rows: [
          [ field("/name", span: 5), field("/item_type", span: 4), field("/portable", span: 3, widget: "checkbox") ],
          [ field("/description", span: 12, widget: "textarea") ],
          [ field("/location_kind", span: 4), field("/location_key", span: 8) ],
          [ field("/notes", span: 12, widget: "textarea") ],
          [ commit(span: 12, commit_mode: "immediate", message_mode: "inline_optional") ]
        ]
      )
    end

    def mud_world_schema
      schema(
        cluster_key: PRIVATE_MUD,
        key: "mud-world",
        title: "MUD World",
        required: %w[name start_room_key],
        properties: {
          "name" => string("Name"),
          "summary" => string("Summary"),
          "start_room_key" => string("Start room"),
          "default_character_key" => string("Default character"),
          "notes" => string("Author notes")
        },
        rows: [
          [ field("/name", span: 6), reference_field("/start_room_key", span: 6, schema_key: "mud-room", placeholder: "Select room") ],
          [ reference_field("/default_character_key", span: 6, schema_key: "mud-character", placeholder: "Select character"), field("/summary", span: 6, widget: "textarea") ],
          [ field("/notes", span: 12, widget: "textarea") ],
          [ commit(span: 12, commit_mode: "immediate", message_mode: "inline_optional") ]
        ],
        view_affordances: [
          mud_player_view_affordance(
            key: "mud-world-play-view-affordance",
            title: "MUD world play view affordance",
            start_room_key: "atrium"
          )
        ]
      )
    end

    def mud_choice_room_schema
      schema(
        cluster_key: PRIVATE_MUD,
        key: "mud-choice-room",
        title: "MUD Choice Room",
        required: %w[name room_type prompt],
        properties: {
          "name" => string("Name"),
          "room_type" => enum_string("Room type", %w[challenge death victory]),
          "stage" => string("Stage"),
          "prompt" => string("Prompt"),
          "terminal_text" => string("Terminal text"),
          "choices" => {
            "type" => "array",
            "title" => "Choices",
            "default" => [],
            "maxItems" => 3,
            "items" => {
              "type" => "object",
              "required" => %w[label outcome target_room_key],
              "properties" => {
                "label" => string("Label"),
                "description" => string("Description"),
                "outcome" => enum_string("Outcome", %w[advance death victory]),
                "target_room_key" => string("Target room")
              },
              "additionalProperties" => false
            }
          },
          "notes" => string("Author notes")
        },
        rows: [
          [ field("/name", span: 5), field("/room_type", span: 3), field("/stage", span: 4) ],
          [ field("/prompt", span: 12, widget: "textarea") ],
          [ field("/terminal_text", span: 12, widget: "textarea", help: "Shown for death and victory rooms.") ],
          [
            array_field(
              "/choices",
              span: 12,
              item_title: property_binding("label"),
              item_subtitle: property_binding("outcome"),
              item_rows: [
                [
                  field("/label", span: 4),
                  field("/outcome", span: 3),
                  reference_field("/target_room_key", span: 5, schema_key: "mud-choice-room", placeholder: "Select next room")
                ],
                [ field("/description", span: 12, widget: "textarea") ]
              ]
            )
          ],
          [ field("/notes", span: 12, widget: "textarea") ],
          [ commit(span: 12, commit_mode: "immediate", message_mode: "inline_optional") ]
        ],
        view_affordances: [
          mud_choice_player_view_affordance(
            key: "mud-choice-room-play-view-affordance",
            title: "MUD choice room play view affordance",
            start_room_key: "wizard-gate"
          )
        ]
      )
    end

    def schema(key:, title:, required:, properties:, rows:, cluster_key: WORLD_BUILDING, screens: nil, view_affordances: [], index_definitions: [])
      {
        key: key,
        title: title,
        body: {
          "$schema" => Document::JSON_SCHEMA_2020_12,
          "$id" => "datawires:clusters/#{cluster_key}/#{key}",
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
          "screens" => screens || default_screens(title:, rows:),
          "subforms" => [],
          "indexes" => index_definitions
        },
        view_affordances: view_affordances
      }
    end

    def registered_schema(schema_module)
      {
        key: schema_module::KEY,
        title: schema_module::BODY.fetch("title"),
        body: schema_module::BODY,
        affordance: nil,
        view_affordances: []
      }
    end

    def schema_home_link(title, description, schema_key:)
      {
        "kind" => "schema",
        "title" => title,
        "description" => description,
        "schema_key" => schema_key
      }
    end

    def timeline_view_affordance(key:, title:, affordance_title:, schema_key:, relative_time_label:, participant_kind: nil)
      {
        key: key,
        title: title,
        affordance_title: affordance_title,
        body: {
          "version" => 1,
          "renderer" => "timeline_d3",
          "title" => affordance_title,
          "config" => {
            "schema_key" => schema_key,
            "relative_time_label" => relative_time_label
          }.tap do |config|
            config["participant_kind"] = participant_kind if participant_kind.present?
          end
        }
      }
    end

    def default_screens(title:, rows:)
      [
        {
          "id" => "main",
          "title" => title,
          "columns" => 12,
          "default_span" => 6,
          "width" => "large",
          "rows" => rows
        }
      ]
    end

    def participant_schema
      {
        "type" => "object",
        "required" => %w[kind key],
        "properties" => {
          "kind" => {
            "type" => "string",
            "title" => "Kind",
            "enum" => %w[person party]
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

    def integer(title)
      {
        "type" => "integer",
        "title" => title,
        "description" => "Relative integer values are allowed to be negative."
      }
    end

    def enum_string(title, values)
      string(title).merge("enum" => values)
    end

    def field(ptr, span:, widget: "auto", help: nil, reference: nil)
      {
        "binding" => {
          "kind" => "document_ptr",
          "ptr" => ptr
        },
        "span" => span,
        "widget" => widget
      }.tap do |cell|
        cell["help"] = help if help.present?
        cell["reference"] = reference if reference.present?
      end
    end

    def reference_field(ptr, span:, schema_key:, index_type: "identity", placeholder: nil, help: nil)
      field(
        ptr,
        span: span,
        widget: "reference",
        help: help,
        reference: {
          "schema_key" => schema_key,
          "index_type" => index_type
        }.tap do |config|
          config["placeholder"] = placeholder if placeholder.present?
        end
      )
    end

    def dynamic_reference_field(ptr, span:, schema_key_from:, index_type: "identity", placeholder: nil, help: nil)
      field(
        ptr,
        span: span,
        widget: "reference",
        help: help,
        reference: {
          "schema_key_from" => schema_key_from,
          "index_type" => index_type
        }.tap do |config|
          config["placeholder"] = placeholder if placeholder.present?
        end
      )
    end

    def array_field(ptr, span:, item_title:, item_subtitle:, item_rows: nil)
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
      ).tap do |cell|
        cell["item_rows"] = item_rows if item_rows.present?
      end
    end

    def property_binding(name)
      {
        "kind" => "property",
        "name" => name
      }
    end

    def value_label_binding
      {
        "kind" => "value_label"
      }
    end

    def none_binding
      {
        "kind" => "none"
      }
    end

    def reference_label_binding(schema_key_property:, key_property:, fixed_schema_key: nil)
      binding = {
        "kind" => "reference_label",
        "key_property" => key_property,
        "index_type" => "identity",
        "index_key" => "document_key"
      }
      if fixed_schema_key.present?
        binding["schema_key"] = fixed_schema_key
      else
        binding["schema_key_property"] = schema_key_property
      end
      binding
    end

    def mud_player_view_affordance(key:, title:, start_room_key:)
      {
        key: key,
        title: title,
        affordance_title: "Play",
        body: {
          "version" => 1,
          "renderer" => "mud_player",
          "title" => "Play",
          "config" => {
            "room_schema_key" => "mud-room",
            "character_schema_key" => "mud-character",
            "item_schema_key" => "mud-item"
          }.tap do |config|
            config["start_room_key"] = start_room_key if start_room_key.present?
          end
        }
      }
    end

    def mud_choice_player_view_affordance(key:, title:, start_room_key:)
      {
        key: key,
        title: title,
        affordance_title: "Choice Play",
        body: {
          "version" => 1,
          "renderer" => "mud_choice_player",
          "title" => "Choice Play",
          "config" => {
            "choice_room_schema_key" => "mud-choice-room"
          }.tap do |config|
            config["start_room_key"] = start_room_key if start_room_key.present?
          end
        }
      }
    end

    def timeline_event_index_definitions
      [
        root_index_definition(
          index_type: "timeline_event",
          key: literal_expression("relative_time"),
          value: root_ptr_expression("/relative_time"),
          label: root_ptr_expression("/title"),
          metadata: {
            "relative_time" => root_ptr_expression("/relative_time"),
            "event_type" => root_ptr_expression("/event_type")
          }
        ),
        root_index_definition(
          index_type: "timeline_participant",
          key: literal_expression("party"),
          value: root_ptr_expression("/party_key"),
          label: root_ptr_expression("/title"),
          metadata: timeline_participant_metadata("party", root_ptr_expression("/party_key"), root_ptr_expression("/event_type"))
        ),
        root_index_definition(
          index_type: "timeline_participant",
          key: literal_expression("person"),
          value: root_ptr_expression("/person_key"),
          label: root_ptr_expression("/title"),
          metadata: timeline_participant_metadata("person", root_ptr_expression("/person_key"), root_ptr_expression("/event_type"))
        ),
        array_index_definition(
          index_type: "timeline_participant",
          source_ptr: "/participants",
          key: ptr_expression("/kind"),
          value: ptr_expression("/key"),
          label: root_ptr_expression("/title"),
          metadata: {
            "kind" => ptr_expression("/kind"),
            "role" => ptr_expression("/role"),
            "notes" => ptr_expression("/notes"),
            "relative_time" => root_ptr_expression("/relative_time"),
            "event_type" => root_ptr_expression("/event_type")
          }
        ),
        root_index_definition(
          index_type: "party_membership",
          key: root_ptr_expression("/party_key"),
          value: root_ptr_expression("/person_key"),
          label: root_ptr_expression("/title"),
          condition: {
            "value" => root_ptr_expression("/event_type"),
            "in" => %w[party_join party_leave]
          },
          metadata: {
            "change" => root_ptr_expression("/event_type", transform: { "strip_prefix" => "party_" }),
            "party_key" => root_ptr_expression("/party_key"),
            "person_key" => root_ptr_expression("/person_key"),
            "relative_time" => root_ptr_expression("/relative_time")
          }
        ),
        array_index_definition(
          index_type: "party_membership",
          source_ptr: "/participants",
          key: root_ptr_expression("/party_key"),
          value: ptr_expression("/key"),
          label: root_ptr_expression("/title"),
          condition: {
            "all" => [
              {
                "value" => root_ptr_expression("/event_type"),
                "in" => %w[party_join party_leave]
              },
              {
                "value" => ptr_expression("/kind"),
                "equals" => "person"
              }
            ]
          },
          metadata: {
            "change" => root_ptr_expression("/event_type", transform: { "strip_prefix" => "party_" }),
            "party_key" => root_ptr_expression("/party_key"),
            "person_key" => ptr_expression("/key"),
            "relative_time" => root_ptr_expression("/relative_time")
          }
        )
      ]
    end

    def timeline_participant_metadata(kind, key_expression, role_expression)
      {
        "kind" => literal_expression(kind),
        "key" => key_expression,
        "role" => role_expression,
        "relative_time" => root_ptr_expression("/relative_time"),
        "event_type" => root_ptr_expression("/event_type")
      }
    end

    def root_index_definition(index_type:, key:, value:, label:, metadata: {}, condition: nil)
      {
        "index_type" => index_type,
        "key" => key,
        "value" => value,
        "label" => label,
        "metadata" => metadata
      }.tap do |definition|
        definition["condition"] = condition if condition.present?
      end
    end

    def array_index_definition(index_type:, source_ptr:, key:, value:, label:, metadata: {}, condition: nil)
      root_index_definition(index_type: index_type, key: key, value: value, label: label, metadata: metadata, condition: condition).merge(
        "source" => {
          "ptr" => source_ptr,
          "each" => true
        }
      )
    end

    def ptr_expression(ptr)
      { "ptr" => ptr }
    end

    def root_ptr_expression(ptr, transform: nil)
      { "root_ptr" => ptr }.tap do |expression|
        expression["transform"] = transform if transform.present?
      end
    end

    def literal_expression(value)
      { "literal" => value }
    end

    def commit(span:, commit_mode: "review_screen", message_mode: "inline_optional")
      {
        "kind" => "commit",
        "span" => span,
        "commit_mode" => commit_mode,
        "message_mode" => message_mode
      }
    end

    def navigation(label, target_screen:, span:)
      {
        "kind" => "navigation",
        "target_screen" => target_screen,
        "label" => label,
        "span" => span
      }
    end
  end
end
