# frozen_string_literal: true

module Seeds
  module AffordanceFixtureExamples
    module_function

    DOMAIN_NAME = "Affordance Fixtures"
    DATAWIRES_DOMAIN_NAME = "Datawires"
    EDIT_FORM_SCHEMA_KEY = "edit-form"
    JSON_SCHEMA_DOCUMENT_KEY = "meta/json-schema/2020-12"

    def seed!
      domain = DocumentSeedHelper.ensure_domain!(name: DOMAIN_NAME)
      edit_form_schema = DocumentSeedHelper.find_document!(
        domain_name: DATAWIRES_DOMAIN_NAME,
        key: EDIT_FORM_SCHEMA_KEY
      )
      json_schema = DocumentSeedHelper.find_document!(
        domain_name: DATAWIRES_DOMAIN_NAME,
        key: JSON_SCHEMA_DOCUMENT_KEY
      )

      fixtures.each do |fixture|
        schema_document = DocumentSeedHelper.ensure_document_with_revision!(
          domain: domain,
          key: fixture.fetch(:schema_key),
          title: fixture.fetch(:schema_title),
          schema_document: json_schema,
          body: fixture.fetch(:schema_body),
          message: "Seed #{fixture.fetch(:schema_title)} fixture schema"
        )
        schema_wrapper = SchemaWrapper.find_or_create_by!(document: schema_document)
        schema_wrapper.update!(public: true) unless schema_wrapper.public?

        DocumentSeedHelper.ensure_document_with_revision!(
          domain: domain,
          key: fixture.fetch(:example_key),
          title: fixture.fetch(:example_title),
          schema_document: schema_document,
          body: fixture.fetch(:example_body),
          message: "Seed #{fixture.fetch(:example_title)} fixture document"
        )

        edit_document = DocumentSeedHelper.ensure_document_with_revision!(
          domain: domain,
          key: fixture.fetch(:edit_key),
          title: "#{fixture.fetch(:schema_title)} Fixture Edit Affordance",
          schema_document: edit_form_schema,
          body: fixture.fetch(:affordance_body),
          message: "Seed #{fixture.fetch(:schema_title)} fixture edit affordance"
        )

        affordance = EditAffordance.find_or_initialize_by(
          schema_wrapper: schema_wrapper,
          edit_document: edit_document
        )
        affordance.title = "Fixture"
        affordance.public = true
        affordance.save!
      end
    end

    def fixtures
      [
        flat_object_fixture,
        nested_object_fixture,
        object_array_fixture,
        scalar_array_fixture,
        mixed_workflow_fixture
      ]
    end

    def flat_object_fixture
      {
        schema_key: "fixture-flat-object",
        schema_title: "Fixture Flat Object",
        example_key: "fixture-flat-object-example",
        example_title: "Fixture Flat Object Example",
        edit_key: "fixture-flat-object-edit",
        schema_body: {
          "$schema" => Document::JSON_SCHEMA_2020_12,
          "$id" => "http://datawires.local/fixtures/flat-object",
          "title" => "Fixture Flat Object",
          "type" => "object",
          "required" => %w[name status priority],
          "properties" => {
            "name" => { "type" => "string", "title" => "Name", "minLength" => 1 },
            "status" => { "type" => "string", "title" => "Status", "enum" => %w[draft active archived] },
            "priority" => { "type" => "integer", "title" => "Priority", "minimum" => 1, "maximum" => 5 },
            "published" => { "type" => "boolean", "title" => "Published", "default" => false },
            "notes" => { "type" => "string", "title" => "Notes" }
          },
          "additionalProperties" => false
        },
        example_body: {
          "name" => "Launch checklist",
          "status" => "active",
          "priority" => 3,
          "published" => false,
          "notes" => "Small flat form for scalar widgets."
        },
        affordance_body: {
          "version" => 1,
          "screen" => { "mode" => "page", "columns" => 6, "default_span" => 3, "commit_mode" => "review_screen" },
          "rows" => [
            [ field("/name", span: 6, help: "Required text field.") ],
            [ field("/status", span: 3), field("/priority", span: 3, widget: "number") ],
            [ field("/published", span: 2, widget: "checkbox"), field("/notes", span: 4, widget: "textarea") ],
            [ commit(span: 6) ]
          ]
        }
      }
    end

    def nested_object_fixture
      {
        schema_key: "fixture-nested-object",
        schema_title: "Fixture Nested Object",
        example_key: "fixture-nested-object-example",
        example_title: "Fixture Nested Object Example",
        edit_key: "fixture-nested-object-edit",
        schema_body: {
          "$schema" => Document::JSON_SCHEMA_2020_12,
          "$id" => "http://datawires.local/fixtures/nested-object",
          "title" => "Fixture Nested Object",
          "type" => "object",
          "required" => %w[name profile],
          "properties" => {
            "name" => { "type" => "string", "title" => "Name" },
            "profile" => {
              "type" => "object",
              "title" => "Profile",
              "required" => %w[display_name email],
              "properties" => {
                "display_name" => { "type" => "string", "title" => "Display name" },
                "email" => { "type" => "string", "title" => "Email" },
                "address" => {
                  "type" => "object",
                  "title" => "Address",
                  "properties" => {
                    "city" => { "type" => "string", "title" => "City" },
                    "region" => { "type" => "string", "title" => "Region" }
                  },
                  "additionalProperties" => false
                }
              },
              "additionalProperties" => false
            }
          },
          "additionalProperties" => false
        },
        example_body: {
          "name" => "Ada",
          "profile" => {
            "display_name" => "Ada Lovelace",
            "email" => "ada@example.test",
            "address" => {
              "city" => "London",
              "region" => "Middlesex"
            }
          }
        },
        affordance_body: {
          "version" => 1,
          "start_screen" => "main",
          "screens" => [
            {
              "id" => "main",
              "title" => "Summary",
              "columns" => 6,
              "default_span" => 3,
              "rows" => [
                [ field("/name", span: 6), field("/profile/display_name", span: 6) ],
                [ navigation("profile", label: "Profile", span: 3), navigation("address", label: "Address", span: 3) ],
                [ commit(span: 6) ]
              ]
            },
            {
              "id" => "profile",
              "title" => "Profile",
              "root_binding" => binding("/profile"),
              "subform" => "profile_fields"
            },
            {
              "id" => "address",
              "title" => "Address",
              "root_binding" => binding("/profile/address"),
              "subform" => "address_fields"
            }
          ],
          "subforms" => [
            { "id" => "profile_fields", "rows" => [ [ field("/display_name", span: 6), field("/email", span: 6) ], [ navigation("main", label: "Back", span: 3), commit(span: 3) ] ] },
            { "id" => "address_fields", "rows" => [ [ field("/city", span: 3), field("/region", span: 3) ], [ navigation("main", label: "Back", span: 3), commit(span: 3) ] ] }
          ]
        }
      }
    end

    def object_array_fixture
      {
        schema_key: "fixture-object-array",
        schema_title: "Fixture Object Array",
        example_key: "fixture-object-array-example",
        example_title: "Fixture Object Array Example",
        edit_key: "fixture-object-array-edit",
        schema_body: {
          "$schema" => Document::JSON_SCHEMA_2020_12,
          "$id" => "http://datawires.local/fixtures/object-array",
          "title" => "Fixture Object Array",
          "type" => "object",
          "required" => [ "tasks" ],
          "properties" => {
            "tasks" => {
              "type" => "array",
              "title" => "Tasks",
              "default" => [],
              "items" => {
                "type" => "object",
                "title" => "Task",
                "default" => { "title" => "", "owner" => "", "done" => false },
                "required" => %w[title owner done],
                "properties" => {
                  "title" => { "type" => "string", "title" => "Title" },
                  "owner" => { "type" => "string", "title" => "Owner" },
                  "done" => { "type" => "boolean", "title" => "Done", "default" => false }
                },
                "additionalProperties" => false
              }
            }
          },
          "additionalProperties" => false
        },
        example_body: {
          "tasks" => [
            { "title" => "Sketch affordance", "owner" => "Meleneth", "done" => true },
            { "title" => "Thrash collection UX", "owner" => "Meleneth", "done" => false }
          ]
        },
        affordance_body: {
          "version" => 1,
          "start_screen" => "main",
          "screens" => [
            {
              "id" => "main",
              "title" => "Tasks",
              "columns" => 6,
              "default_span" => 6,
              "rows" => [
                [ array_field("/tasks", span: 6, collection: collection(presentation: "table", creation: "new_screen", delete: "enabled", reorder: "enabled", item_screen: "task", item_title: property_binding("title"), item_subtitle: property_binding("owner"))) ],
                [ commit(span: 6) ]
              ]
            },
            { "id" => "task", "title" => "Task", "root_binding" => binding("/tasks/:index"), "subform" => "task_fields" }
          ],
          "subforms" => [
            { "id" => "task_fields", "rows" => [ [ field("/title", span: 6), field("/owner", span: 4), field("/done", span: 2, widget: "checkbox") ], [ navigation("main", label: "Back", span: 3), commit(span: 3) ] ] }
          ]
        }
      }
    end

    def scalar_array_fixture
      {
        schema_key: "fixture-scalar-array",
        schema_title: "Fixture Scalar Array",
        example_key: "fixture-scalar-array-example",
        example_title: "Fixture Scalar Array Example",
        edit_key: "fixture-scalar-array-edit",
        schema_body: {
          "$schema" => Document::JSON_SCHEMA_2020_12,
          "$id" => "http://datawires.local/fixtures/scalar-array",
          "title" => "Fixture Scalar Array",
          "type" => "object",
          "required" => %w[title tags],
          "properties" => {
            "title" => { "type" => "string", "title" => "Title" },
            "tags" => {
              "type" => "array",
              "title" => "Tags",
              "default" => [],
              "items" => { "type" => "string", "title" => "Tag", "default" => "" }
            }
          },
          "additionalProperties" => false
        },
        example_body: {
          "title" => "Tagged note",
          "tags" => %w[affordance fixture scalar]
        },
        affordance_body: {
          "version" => 1,
          "screen" => { "mode" => "page", "columns" => 6, "default_span" => 6, "commit_mode" => "review_screen" },
          "rows" => [
            [ field("/title", span: 6) ],
            [ array_field("/tags", span: 6, collection: collection(presentation: "cards", creation: "inline_blank_form", delete: "enabled", reorder: "enabled", item_title: value_label_binding)) ],
            [ commit(span: 6) ]
          ]
        }
      }
    end

    def mixed_workflow_fixture
      {
        schema_key: "fixture-mixed-workflow",
        schema_title: "Fixture Mixed Workflow",
        example_key: "fixture-mixed-workflow-example",
        example_title: "Fixture Mixed Workflow Example",
        edit_key: "fixture-mixed-workflow-edit",
        schema_body: {
          "$schema" => Document::JSON_SCHEMA_2020_12,
          "$id" => "http://datawires.local/fixtures/mixed-workflow",
          "title" => "Fixture Mixed Workflow",
          "type" => "object",
          "required" => %w[summary owner milestones tags],
          "properties" => {
            "summary" => { "type" => "string", "title" => "Summary" },
            "owner" => { "type" => "string", "title" => "Owner" },
            "notes" => { "type" => "string", "title" => "Notes" },
            "tags" => { "type" => "array", "title" => "Tags", "default" => [], "items" => { "type" => "string", "default" => "" } },
            "milestones" => {
              "type" => "array",
              "title" => "Milestones",
              "default" => [],
              "items" => {
                "type" => "object",
                "title" => "Milestone",
                "default" => { "name" => "", "state" => "planned", "notes" => "" },
                "required" => %w[name state],
                "properties" => {
                  "name" => { "type" => "string", "title" => "Name" },
                  "state" => { "type" => "string", "title" => "State", "enum" => %w[planned active done] },
                  "notes" => { "type" => "string", "title" => "Notes" }
                },
                "additionalProperties" => false
              }
            }
          },
          "additionalProperties" => false
        },
        example_body: {
          "summary" => "Self-hosting pass",
          "owner" => "Meleneth",
          "notes" => "Use this to exercise navigation, arrays, and commit review.",
          "tags" => %w[self-hosting builder],
          "milestones" => [
            { "name" => "Seed examples", "state" => "done", "notes" => "Fixture data exists." },
            { "name" => "Thrash UX", "state" => "active", "notes" => "Try to break repair flows." }
          ]
        },
        affordance_body: {
          "version" => 1,
          "start_screen" => "main",
          "commit_mode" => "review_screen",
          "screens" => [
            {
              "id" => "main",
              "title" => "Workflow",
              "columns" => 6,
              "default_span" => 6,
              "rows" => [
                [ field("/summary", span: 6), field("/owner", span: 3) ],
                [ navigation("details", label: "Details", span: 3) ],
                [ array_field("/milestones", span: 6, collection: collection(presentation: "cards", creation: "new_screen", delete: "enabled", reorder: "enabled", item_screen: "milestone", item_title: property_binding("name"), item_subtitle: property_binding("state"))) ],
                [ array_field("/tags", span: 6, collection: collection(presentation: "list", creation: "inline_blank_form", delete: "enabled", reorder: "enabled", item_title: value_label_binding)) ],
                [ commit(span: 6) ]
              ]
            },
            {
              "id" => "details",
              "title" => "Details",
              "columns" => 6,
              "default_span" => 6,
              "rows" => [
                [ field("/notes", span: 6, widget: "textarea") ],
                [ navigation("main", label: "Back", span: 3), commit(span: 3) ]
              ]
            },
            { "id" => "milestone", "title" => "Milestone", "root_binding" => binding("/milestones/:index"), "subform" => "milestone_fields" }
          ],
          "subforms" => [
            { "id" => "milestone_fields", "rows" => [ [ field("/name", span: 6), field("/state", span: 3), field("/notes", span: 3, widget: "textarea") ], [ navigation("main", label: "Back", span: 3), commit(span: 3) ] ] }
          ]
        }
      }
    end

    def field(ptr, span:, widget: "auto", help: nil)
      { "binding" => binding(ptr), "span" => span, "widget" => widget }.tap do |cell|
        cell["help"] = help if help.present?
      end
    end

    def array_field(ptr, span:, collection:)
      field(ptr, span: span, widget: "array").merge("collection" => collection)
    end

    def navigation(target_screen, label:, span:)
      { "kind" => "navigation", "target_screen" => target_screen, "label" => label, "span" => span }
    end

    def commit(span:)
      { "kind" => "commit", "span" => span, "message_mode" => "inline_optional" }
    end

    def binding(ptr)
      { "kind" => "document_ptr", "ptr" => ptr }
    end

    def collection(presentation:, creation:, delete:, reorder:, item_title:, item_screen: nil, item_subtitle: nil)
      {
        "behavior" => "list_open",
        "presentation" => presentation,
        "creation" => creation,
        "navigation" => "open_item",
        "delete" => delete,
        "reorder" => reorder,
        "item_title" => item_title,
        "item_subtitle" => item_subtitle || value_label_binding
      }.tap do |config|
        config["item_screen"] = item_screen if item_screen.present?
      end
    end

    def property_binding(name)
      { "kind" => "property", "name" => name }
    end

    def value_label_binding
      { "kind" => "value_label" }
    end
  end
end
