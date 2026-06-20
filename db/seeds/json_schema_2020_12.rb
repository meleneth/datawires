# frozen_string_literal: true

module Seeds
  module JsonSchema202012
    module_function

    DOMAIN_NAME = "Datawires"
    VENDOR_ROOT = Rails.root.join("db/seeds/vendor/json_schema_2020_12")
    ROOT_KEY = "meta/json-schema/2020-12"
    ROOT_ID = "https://json-schema.org/draft/2020-12/schema"

    DOCUMENTS = {
      ROOT_KEY => "schema.json",
      "meta/json-schema/2020-12/core" => "core.json",
      "meta/json-schema/2020-12/applicator" => "applicator.json",
      "meta/json-schema/2020-12/unevaluated" => "unevaluated.json",
      "meta/json-schema/2020-12/validation" => "validation.json",
      "meta/json-schema/2020-12/meta-data" => "meta-data.json",
      "meta/json-schema/2020-12/format-annotation" => "format-annotation.json",
      "meta/json-schema/2020-12/content" => "content.json"
    }.freeze

    def seed!
      domain = DocumentSeedHelper.ensure_domain!(name: DOMAIN_NAME)

      documents = DOCUMENTS.each_with_object({}) do |(key, file_name), memo|
        body = read_json(file_name)

        memo[key] = DocumentSeedHelper.ensure_document_with_revision!(
          domain:,
          key:,
          title: body["title"] || key,
          body:,
          message: "Seed JSON Schema 2020-12 meta-schema"
        )
      end

      root_document = documents.fetch(ROOT_KEY)

      documents.each_value do |document|
        document.update!(schema_document: root_document) if document.schema_document != root_document
        SchemaWrapper.find_or_create_by!(document:)
      end
    end

    def read_json(file_name)
      JSON.parse(VENDOR_ROOT.join(file_name).read)
    end
  end
end
