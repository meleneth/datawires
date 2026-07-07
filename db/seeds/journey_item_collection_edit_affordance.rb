# db/seeds/journey_item_collection_edit_affordance.rb
# frozen_string_literal: true

module Seeds
  module JourneyItemCollectionEditAffordance
    module_function

    JOURNEY_DOMAIN_NAME = "Journey".freeze
    JOURNEY_SCHEMA_KEY = "items".freeze

    DATAWIRES_DOMAIN_NAME = "Datawires".freeze
    EDIT_FORM_SCHEMA_KEY = "edit-form".freeze

    EDIT_DOCUMENT_KEY = "journey-item-collection-default-edit".freeze
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
        title: "Journey Item Collection Default Edit Affordance",
        schema_document: edit_form_schema,
        body: affordance_body,
        message: "Seed Journey Item Collection default edit affordance"
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
          "default_span" => 6,
          "commit_mode" => "review_screen"
        },
        "rows" => [
          [
            array_cell("/items", span: 6)
          ],
          [
            { "kind" => "commit", "span" => 6, "message_mode" => "inline_optional" }
          ]
        ]
      }
    end

    def array_cell(ptr, span:, label: nil)
      {
        "binding" => document_ptr_binding(ptr),
        "span" => span,
        "widget" => "array"
      }.tap do |cell|
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
