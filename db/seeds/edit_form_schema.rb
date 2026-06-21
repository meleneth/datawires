# frozen_string_literal: true

module Seeds
  module EditFormSchema
    module_function

    DOMAIN_NAME = "Datawires"
    DOCUMENT_KEY = "edit-form"
    DOCUMENT_TITLE = "Edit Form"
    JSON_SCHEMA_DOCUMENT_KEY = "meta/json-schema/2020-12"

    def seed!
      domain = DocumentSeedHelper.find_domain!(name: DOMAIN_NAME)
      schema_document = DocumentSeedHelper.find_document!(
        domain_name: DOMAIN_NAME,
        key: JSON_SCHEMA_DOCUMENT_KEY
      )

      document = DocumentSeedHelper.ensure_document_with_revision!(
        domain:,
        key: DOCUMENT_KEY,
        title: DOCUMENT_TITLE,
        schema_document:,
        body: schema_body,
        message: "Seed edit form schema"
      )

      SchemaWrapper.find_or_create_by!(document:)
    end

    def schema_body
      {
        "$schema" => "https://json-schema.org/draft/2020-12/schema",
        "$id" => "http://datawires/schemas/edit-form",
        "title" => DOCUMENT_TITLE,
        "type" => "object",
        "required" => %w[version screen rows],
        "additionalProperties" => false,

        "properties" => {
          "version" => {
            "type" => "integer",
            "const" => 1
          },

          "screen" => {
            "type" => "object",
            "required" => %w[mode columns default_span commit_mode],
            "additionalProperties" => false,
            "properties" => {
              "mode" => {
                "type" => "string",
                "enum" => %w[page full_width]
              },
              "columns" => {
                "type" => "integer",
                "minimum" => 1
              },
              "default_span" => {
                "type" => "integer",
                "minimum" => 1
              },
              "commit_mode" => {
                "type" => "string",
                "enum" => %w[immediate review_screen]
              }
            }
          },

          "rows" => {
            "type" => "array",
            "items" => {
              "type" => "array",
              "minItems" => 1,
              "items" => {
                "$ref" => "#/$defs/cell"
              }
            }
          }
        },

        "$defs" => {
          "document_ptr_binding" => {
            "type" => "object",
            "required" => %w[kind ptr],
            "additionalProperties" => false,
            "properties" => {
              "kind" => {
                "type" => "string",
                "const" => "document_ptr"
              },
              "ptr" => {
                "type" => "string",
                "minLength" => 1
              }
            }
          },

          "binding" => {
            "oneOf" => [
              { "$ref" => "#/$defs/document_ptr_binding" }
            ]
          },

          "field_cell" => {
            "type" => "object",
            "required" => [ "binding" ],
            "additionalProperties" => false,
            "properties" => {
              "binding" => {
                "$ref" => "#/$defs/binding"
              },
              "span" => {
                "type" => "integer",
                "minimum" => 1
              },
              "widget" => {
                "type" => "string",
                "enum" => %w[array auto checkbox number select text textarea]
              },
              "label" => {
                "type" => "boolean"
              }
            }
          },

          "commit_cell" => {
            "type" => "object",
            "required" => [ "kind" ],
            "additionalProperties" => false,
            "properties" => {
              "kind" => {
                "type" => "string",
                "const" => "commit"
              },
              "span" => {
                "type" => "integer",
                "minimum" => 1
              },
              "message_mode" => {
                "type" => "string",
                "enum" => %w[hidden inline_optional inline_required]
              }
            }
          },

          "cell" => {
            "oneOf" => [
              { "$ref" => "#/$defs/field_cell" },
              { "$ref" => "#/$defs/commit_cell" }
            ]
          }
        }
      }
    end
  end
end
