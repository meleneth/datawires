# frozen_string_literal: true

module Seeds
  module JourneyItemCollectionSchema
    module_function

    DOMAIN_NAME = "Journey"
    DOCUMENT_KEY = "items"
    DOCUMENT_TITLE = "Items"

    JSON_SCHEMA_DOMAIN_NAME = "Datawires"
    JSON_SCHEMA_DOCUMENT_KEY = "meta/json-schema/2020-12"

    def seed!
      domain = DocumentSeedHelper.find_domain!(name: DOMAIN_NAME)
      schema_document = DocumentSeedHelper.find_document!(
        domain_name: JSON_SCHEMA_DOMAIN_NAME,
        key: JSON_SCHEMA_DOCUMENT_KEY
      )

      document = DocumentSeedHelper.ensure_document_with_revision!(
        domain:,
        key: DOCUMENT_KEY,
        title: DOCUMENT_TITLE,
        schema_document:,
        body: schema_body,
        message: "Seed items schema"
      )

      SchemaWrapper.find_or_create_by!(document:)
    end

    def schema_body
      {
        "$schema" => "https://json-schema.org/draft/2020-12/schema",
        "title" => DOCUMENT_TITLE,
        "type" => "object",
        "properties" => {
          "items" => {
            "type" => "array",
            "title" => "Items",
            "default" => [],
            "items" => {
              "type" => "object",
              "title" => "Item",
              "default" => {
                "name" => "",
                "level" => 1,
                "description" => "",
                "source" => "drop"
              },
              "properties" => {
                "name" => {
                  "type" => "string",
                  "title" => "Name"
                },
                "level" => {
                  "type" => "integer",
                  "title" => "Level",
                  "minimum" => 1
                },
                "description" => {
                  "type" => "string",
                  "title" => "Description"
                },
                "source" => {
                  "type" => "string",
                  "title" => "Source",
                  "enum" => %w[drop crafted conjured]
                }
              },
              "required" => %w[name level description source],
              "additionalProperties" => false
            }
          }
        },
        "required" => [ "items" ],
        "additionalProperties" => false
      }
    end
  end
end
