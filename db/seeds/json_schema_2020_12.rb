# frozen_string_literal: true

module Seeds
  module JsonSchema202012
    module_function

    DOMAIN_NAME = "Datawires"
    DOCUMENT_KEY = "meta/json-schema/2020-12"
    DOCUMENT_TITLE = "JSON Schema 2020-12"

    def seed!
      domain = DocumentSeedHelper.ensure_domain!(name: DOMAIN_NAME)

      document = DocumentSeedHelper.ensure_document_with_revision!(
        domain:,
        key: DOCUMENT_KEY,
        title: DOCUMENT_TITLE,
        body: schema_body,
        message: "Seed JSON Schema 2020-12 meta-schema"
      )

      SchemaWrapper.find_or_create_by!(document:)
    end

    def schema_body
      {
        "$schema" => Document::JSON_SCHEMA_2020_12,
        "$id" => "https://json-schema.org/draft/2020-12/schema",
        "title" => DOCUMENT_TITLE,
        "type" => [ "object", "boolean" ]
      }
    end
  end
end
