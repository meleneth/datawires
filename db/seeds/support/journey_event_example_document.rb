# frozen_string_literal: true

module Seeds
  module JourneyEventExampleDocument
    module_function

    DOMAIN_NAME = "Journey".freeze
    DOCUMENT_KEY = "event/example".freeze

    def seed!
      domain = DocumentSeedHelper.find_domain!(name: DOMAIN_NAME)
      schema_document = DocumentSeedHelper.find_document!(
        domain_name: DOMAIN_NAME,
        key: "event"
      )

      DocumentSeedHelper.ensure_document_with_revision!(
        domain:,
        key: DOCUMENT_KEY,
        title: "Journey Event Example",
        schema_document:,
        body: document_body,
        message: "Seed Journey Event example document"
      )
    end

    def document_body
      {
        "title" => "Found Sanders Riprap",
        "act" => "Act III",
        "area" => "Lower Kurast",
        "item_name" => "Sanders Riprap",
        "difficulty" => "Normal",
        "event_type" => "item_find",
        "character_name" => "Boyle",
        "character_class" => "Warlock",
        "character_level" => 28
      }
    end
  end
end
