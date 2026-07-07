# frozen_string_literal: true

module Seeds
  module EditFormEditAffordance
    module_function

    DOMAIN_NAME = "Datawires".freeze
    EDIT_FORM_SCHEMA_KEY = "edit-form".freeze
    EDIT_DOCUMENT_KEY = "edit-form-default-edit-affordance".freeze
    EDIT_AFFORDANCE_TITLE = "Default".freeze

    def seed!
      domain = DocumentSeedHelper.find_domain!(name: DOMAIN_NAME)
      edit_form_schema = DocumentSeedHelper.find_document!(
        domain_name: DOMAIN_NAME,
        key: EDIT_FORM_SCHEMA_KEY
      )
      schema_wrapper = SchemaWrapper.find_by!(document: edit_form_schema)

      edit_document = DocumentSeedHelper.ensure_document_with_revision!(
        domain: domain,
        key: EDIT_DOCUMENT_KEY,
        title: "Edit Form Default Edit Affordance",
        schema_document: edit_form_schema,
        body: affordance_body,
        message: "Seed Edit Form default edit affordance"
      )

      EditAffordance.find_or_create_by!(
        schema_wrapper: schema_wrapper,
        edit_document: edit_document
      ) do |edit_affordance|
        edit_affordance.title = EDIT_AFFORDANCE_TITLE
        edit_affordance.public = true
      end.tap do |edit_affordance|
        edit_affordance.update!(public: true) unless edit_affordance.public?
      end
    end

    def affordance_body
      {
        "version" => 1,
        "start_screen" => "main",
        "commit_mode" => "review_screen",
        "subforms" => [
          {
            "id" => "screen_fields",
            "rows" => [
              [
                field_cell("/id", span: 3),
                field_cell("/title", span: 3),
                field_cell("/subform", span: 3),
                field_cell("/width", span: 3, widget: "select")
              ],
              [
                field_cell("/commit_mode", span: 3, widget: "select"),
                field_cell("/root_binding/ptr", span: 3, help: "Use path variables such as /items/:index."),
                array_cell("/rows", span: 6, title_name: nil, subtitle_kind: "value_label")
              ]
            ]
          },
          {
            "id" => "subform_fields",
            "rows" => [
              [
                field_cell("/id", span: 4),
                field_cell("/root_binding/ptr", span: 8, help: "Optional root for rows reused by screens.")
              ],
              [
                array_cell("/rows", span: 12, title_name: nil, subtitle_kind: "value_label")
              ]
            ]
          }
        ],
        "screens" => [
          {
            "id" => "main",
            "title" => "Affordance",
            "columns" => 12,
            "default_span" => 3,
            "width" => "large",
            "rows" => [
              [
                field_cell("/version", span: 2, widget: "number"),
                field_cell("/start_screen", span: 3),
                field_cell("/width", span: 2, widget: "select"),
                field_cell("/commit_mode", span: 3, widget: "select"),
                { "kind" => "commit", "span" => 2, "message_mode" => "inline_optional" }
              ],
              [
                array_cell("/screens", span: 6, item_screen: "screen", title_name: "id"),
                array_cell("/subforms", span: 6, item_screen: "subform", title_name: "id")
              ]
            ]
          },
          {
            "id" => "screen",
            "title" => "Screen",
            "root_binding" => document_ptr_binding("/screens/:index"),
            "subform" => "screen_fields"
          },
          {
            "id" => "subform",
            "title" => "Subform",
            "root_binding" => document_ptr_binding("/subforms/:index"),
            "subform" => "subform_fields"
          }
        ]
      }
    end

    def field_cell(ptr, span:, widget: nil, help: nil)
      {
        "binding" => document_ptr_binding(ptr),
        "span" => span
      }.tap do |cell|
        cell["widget"] = widget unless widget.nil?
        cell["help"] = help unless help.nil?
      end
    end

    def array_cell(ptr, span:, item_screen: nil, title_name: "id", subtitle_kind: "value_label")
      {
        "binding" => document_ptr_binding(ptr),
        "span" => span,
        "widget" => "array",
        "collection" => collection_config(item_screen: item_screen, title_name: title_name, subtitle_kind: subtitle_kind)
      }
    end

    def collection_config(item_screen:, title_name:, subtitle_kind:)
      config = EditAffordances::Collection.default_config.merge(
        "presentation" => "cards",
        "creation" => "new_screen",
        "delete" => "enabled",
        "reorder" => "enabled",
        "item_subtitle" => {
          "kind" => subtitle_kind
        }
      )
      config["item_screen"] = item_screen if item_screen.present?
      config["item_title"] = if title_name.present?
        {
          "kind" => "property",
          "name" => title_name
        }
      else
        {
          "kind" => "value_label"
        }
      end
      config
    end

    def document_ptr_binding(ptr)
      {
        "kind" => "document_ptr",
        "ptr" => ptr
      }
    end
  end
end
