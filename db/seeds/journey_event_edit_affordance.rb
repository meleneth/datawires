# db/seeds/journey_event_edit_affordance.rb
# frozen_string_literal: true

module Seeds
  module JourneyEventEditAffordance
    module_function

    JOURNEY_DOMAIN_NAME = "Journey".freeze
    JOURNEY_SCHEMA_KEY = "event".freeze

    DATAWIRES_DOMAIN_NAME = "Datawires".freeze
    EDIT_FORM_SCHEMA_KEY = "edit-form".freeze

    AFFORDANCE_DOCUMENT_KEY = "journey-event-default-edit".freeze
    AFFORDANCE_NAME = "Default".freeze

    def seed!
      journey_domain = DocumentSeedHelper.ensure_domain!(name: JOURNEY_DOMAIN_NAME)
      datawires_domain = DocumentSeedHelper.ensure_domain!(name: DATAWIRES_DOMAIN_NAME)

      journey_schema = Document.find_by!(domain: journey_domain, key: JOURNEY_SCHEMA_KEY)
      edit_form_schema = Document.find_by!(domain: datawires_domain, key: EDIT_FORM_SCHEMA_KEY)

      affordance_document = DocumentSeedHelper.ensure_document_with_revision!(
        domain: journey_domain,
        key: AFFORDANCE_DOCUMENT_KEY,
        title: "Journey Event Default Edit Affordance",
        schema_document: edit_form_schema,
        body: affordance_body,
        message: "Seed Journey Event default edit affordance"
      )

      EditAffordance.find_or_create_by!(
        for_schema_document: journey_schema,
        affordance_document: affordance_document
      ) do |edit_affordance|
        edit_affordance.name = AFFORDANCE_NAME
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
            { "ptr" => "/title", "span" => 6 }
          ],
          [
            { "ptr" => "/event_type", "span" => 3 },
            { "ptr" => "/occurred_at", "span" => 3 }
          ],
          [
            { "ptr" => "/character_name", "span" => 2 },
            { "ptr" => "/character_class", "span" => 2 },
            { "ptr" => "/character_level", "span" => 2 }
          ],
          [
            { "ptr" => "/difficulty", "span" => 2 },
            { "ptr" => "/act", "span" => 2 },
            { "ptr" => "/area", "span" => 2 }
          ],
          [
            { "ptr" => "/item_name", "span" => 3 },
            { "ptr" => "/item_quality", "span" => 3 }
          ],
          [
            { "ptr" => "/notable", "span" => 2 },
            { "ptr" => "/notes", "span" => 4, "widget" => "textarea" }
          ],
          [
            { "kind" => "commit", "span" => 6, "message_mode" => "inline_optional" }
          ]
        ]
      }
    end
  end
end
