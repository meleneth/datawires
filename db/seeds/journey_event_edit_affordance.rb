# db/seeds/journey_event_edit_affordance.rb
# frozen_string_literal: true

module Seeds
  module JourneyEventEditAffordance
    module_function

    JOURNEY_DOMAIN_NAME = "Journey".freeze
    JOURNEY_SCHEMA_KEY = "event".freeze

    DATAWIRES_DOMAIN_NAME = "Datawires".freeze
    EDIT_FORM_SCHEMA_KEY = "edit-form".freeze

    EDIT_DOCUMENT_KEY = "journey-event-default-edit".freeze
    EDIT_AFFORDANCE_TITLE = "Default".freeze

    def seed!
      journey_domain = DocumentSeedHelper.ensure_domain!(name: JOURNEY_DOMAIN_NAME)
      datawires_domain = DocumentSeedHelper.ensure_domain!(name: DATAWIRES_DOMAIN_NAME)

      journey_schema_wrapper = SchemaWrapper.joins(:document).find_by!(
        documents: { domain_id: journey_domain.id, key: JOURNEY_SCHEMA_KEY }
      )

      edit_form_schema = Document.find_by!(
        domain: datawires_domain,
        key: EDIT_FORM_SCHEMA_KEY
      )

      edit_document = DocumentSeedHelper.ensure_document_with_revision!(
        domain: journey_domain,
        key: EDIT_DOCUMENT_KEY,
        title: "Journey Event Default Edit Affordance",
        schema_document: edit_form_schema,
        body: affordance_body,
        message: "Seed Journey Event default edit affordance"
      )

      EditAffordance.find_or_create_by!(
        schema_wrapper: journey_schema_wrapper,
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
        "screen" => {
          "mode" => "page",
          "columns" => 6,
          "default_span" => 3,
          "commit_mode" => "review_screen"
        },
        "rows" => [
          [
            field_cell("/title", span: 6)
          ],
          [
            field_cell("/event_type", span: 3),
            field_cell("/occurred_at", span: 3)
          ],
          [
            field_cell("/character_name", span: 2),
            field_cell("/character_class", span: 2),
            field_cell("/character_level", span: 2)
          ],
          [
            field_cell("/difficulty", span: 2),
            field_cell("/act", span: 2),
            field_cell("/area", span: 2)
          ],
          [
            field_cell("/item_name", span: 3),
            field_cell("/item_quality", span: 3)
          ],
          [
            field_cell("/notable", span: 2),
            field_cell("/notes", span: 4, widget: "textarea")
          ],
          [
            { "kind" => "commit", "span" => 6, "message_mode" => "inline_optional" }
          ]
        ]
      }
    end

    def field_cell(ptr, span:, widget: nil, label: nil)
      {
        "binding" => document_ptr_binding(ptr),
        "span" => span
      }.tap do |cell|
        cell["widget"] = widget unless widget.nil?
        cell["label"] = label unless label.nil?
      end
    end

    def document_ptr_binding(ptr)
      {
        "kind" => "document_ptr",
        "ptr" => ptr
      }
    end
  end
end
