# frozen_string_literal: true

module Clusters
  module Catalog
    module_function

    WORLD_BUILDING = "worldbuilding"
    ROBERTS_RULES = "roberts-rules"

    def options
      [
        [ "Blank", "" ],
        [ "Worldbuilding tools", WORLD_BUILDING ],
        [ "Robert's Rules of Order", ROBERTS_RULES ]
      ]
    end

    def include?(key)
      key.blank? || key == WORLD_BUILDING || key == ROBERTS_RULES
    end

    def definition_for(key)
      return nil if key.blank?
      return worldbuilding if key == WORLD_BUILDING
      return roberts_rules if key == ROBERTS_RULES

      raise ArgumentError, "unknown cluster: #{key}"
    end

    def worldbuilding
      {
        key: WORLD_BUILDING,
        name: "Worldbuilding tools",
        repository_mode: false,
        schemas: [
          person_schema,
          place_schema,
          thing_schema,
          party_schema,
          timeline_event_schema
        ]
      }
    end

    def roberts_rules
      {
        key: ROBERTS_RULES,
        name: "Robert's Rules of Order",
        repository_mode: true,
        schemas: [
          agreement_schema,
          motion_schema,
          proceeding_event_schema,
          meeting_state_schema
        ]
      }
    end

    def agreement_schema
      schema(
        cluster_key: ROBERTS_RULES,
        key: "agreement",
        title: "Agreement",
        required: %w[title status body],
        properties: {
          "title" => string("Title"),
          "status" => enum_string("Status", %w[proposed active amended adopted rejected withdrawn superseded closed]),
          "body" => string("Agreement text"),
          "relative_time" => integer("Relative time"),
          "supersedes_agreement_key" => string("Supersedes agreement key"),
          "extends_agreement_key" => string("Extends agreement key"),
          "notes" => string("Notes")
        },
        rows: [
          [ field("/title", span: 6), field("/status", span: 3), field("/relative_time", span: 3, widget: "number") ],
          [ field("/body", span: 12, widget: "textarea") ],
          [
            reference_field("/supersedes_agreement_key", span: 6, schema_key: "agreement", placeholder: "Select superseded agreement"),
            reference_field("/extends_agreement_key", span: 6, schema_key: "agreement", placeholder: "Select extended agreement")
          ],
          [ field("/notes", span: 12, widget: "textarea") ],
          [ commit(span: 12) ]
        ]
      )
    end

    def motion_schema
      schema(
        cluster_key: ROBERTS_RULES,
        key: "motion",
        title: "Motion",
        required: %w[title motion_type status relative_time],
        properties: {
          "title" => string("Title"),
          "motion_type" => enum_string("Motion type", %w[main extend amend postpone table call_question reconsider point_of_order appeal withdraw close]),
          "status" => enum_string("Status", %w[pending seconded open adopted rejected withdrawn expired]),
          "relative_time" => integer("Relative time"),
          "new_agreement_key" => string("New agreement key"),
          "target_agreement_key" => string("Target agreement key"),
          "proposed_text" => string("Proposed text"),
          "mover_key" => string("Mover key"),
          "seconder_key" => string("Seconder key"),
          "result" => string("Result"),
          "notes" => string("Notes")
        },
        rows: [],
        screens: motion_screens
      )
    end

    def proceeding_event_schema
      schema(
        cluster_key: ROBERTS_RULES,
        key: "proceeding-event",
        title: "Proceeding Event",
        required: %w[relative_time event_type title],
        properties: {
          "relative_time" => integer("Relative time"),
          "event_type" => enum_string("Event type", %w[start_meeting introduce_motion second_motion open_debate amend_motion vote rule adjourn note]),
          "title" => string("Title"),
          "motion_key" => string("Motion key"),
          "agreement_key" => string("Agreement key"),
          "summary" => string("Summary"),
          "notes" => string("Notes")
        },
        rows: [
          [ field("/relative_time", span: 3, widget: "number"), field("/event_type", span: 3), field("/title", span: 6) ],
          [
            reference_field("/motion_key", span: 6, schema_key: "motion", placeholder: "Select motion"),
            reference_field("/agreement_key", span: 6, schema_key: "agreement", placeholder: "Select agreement")
          ],
          [ field("/summary", span: 12, widget: "textarea") ],
          [ field("/notes", span: 12, widget: "textarea") ],
          [ commit(span: 12) ]
        ],
        view_affordances: [
          timeline_view_affordance(
            key: "proceeding-event-sequence-view-affordance",
            title: "Proceeding Event sequence view affordance",
            affordance_title: "Proceeding Sequence",
            schema_key: "proceeding-event",
            relative_time_label: "Meeting-relative time"
          )
        ]
      )
    end

    def meeting_state_schema
      schema(
        cluster_key: ROBERTS_RULES,
        key: "meeting-state",
        title: "Meeting State",
        required: %w[name phase],
        properties: {
          "name" => string("Name"),
          "phase" => enum_string("Phase", %w[not_started in_session recessed adjourned]),
          "current_motion_key" => string("Current motion key"),
          "current_agreement_key" => string("Current agreement key"),
          "notes" => string("Notes")
        },
        rows: [
          [ field("/name", span: 6), field("/phase", span: 6) ],
          [
            reference_field("/current_motion_key", span: 6, schema_key: "motion", placeholder: "Select current motion"),
            reference_field("/current_agreement_key", span: 6, schema_key: "agreement", placeholder: "Select current agreement")
          ],
          [ field("/notes", span: 12, widget: "textarea") ],
          [ commit(span: 12) ]
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

    def schema(key:, title:, required:, properties:, rows:, cluster_key: WORLD_BUILDING, screens: nil, view_affordances: [])
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
          "subforms" => []
        },
        view_affordances: view_affordances
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

    def motion_screens
      [
        {
          "id" => "main",
          "title" => "Motion",
          "columns" => 12,
          "default_span" => 6,
          "width" => "large",
          "rows" => [
            [ field("/relative_time", span: 3, widget: "number"), field("/motion_type", span: 3), field("/status", span: 3), field("/title", span: 3) ],
            [ field("/proposed_text", span: 12, widget: "textarea") ],
            [ navigation("Agreement effect", target_screen: "agreement_effect", span: 6), navigation("People and result", target_screen: "people_result", span: 6) ]
          ]
        },
        {
          "id" => "agreement_effect",
          "title" => "Agreement Effect",
          "columns" => 12,
          "default_span" => 6,
          "width" => "large",
          "rows" => [
            [
              field("/new_agreement_key", span: 6, help: "For main and extend motions that create a new agreement."),
              reference_field("/target_agreement_key", span: 6, schema_key: "agreement", placeholder: "Select target agreement")
            ],
            [ navigation("Motion details", target_screen: "main", span: 6), navigation("People and result", target_screen: "people_result", span: 6) ]
          ]
        },
        {
          "id" => "people_result",
          "title" => "People and Result",
          "columns" => 12,
          "default_span" => 6,
          "width" => "large",
          "rows" => [
            [ field("/mover_key", span: 6), field("/seconder_key", span: 6) ],
            [ field("/result", span: 6), field("/notes", span: 6, widget: "textarea") ],
            [ navigation("Motion details", target_screen: "main", span: 6), navigation("Agreement effect", target_screen: "agreement_effect", span: 6) ],
            [ commit(span: 12) ]
          ]
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

    def reference_label_binding(schema_key_property:, key_property:)
      {
        "kind" => "reference_label",
        "schema_key_property" => schema_key_property,
        "key_property" => key_property,
        "index_type" => "identity",
        "index_key" => "document_key"
      }
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
