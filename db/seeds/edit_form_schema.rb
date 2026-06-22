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
        "required" => %w[version],
        "additionalProperties" => false,

        "properties" => {
          "version" => {
            "type" => "integer",
            "const" => 1
          },

          "start_screen" => {
            "type" => "string"
          },

          "commit_mode" => {
            "$ref" => "#/$defs/commit_mode"
          },

          "screen" => {
            "$ref" => "#/$defs/screen_config"
          },

          "rows" => {
            "$ref" => "#/$defs/rows"
          },

          "screens" => {
            "type" => "array",
            "items" => {
              "$ref" => "#/$defs/screen"
            }
          },

          "subforms" => {
            "type" => "array",
            "items" => {
              "$ref" => "#/$defs/subform"
            }
          }
        },

        "$defs" => {
          "commit_mode" => {
            "type" => "string",
            "enum" => %w[immediate review_screen]
          },

          "screen_mode" => {
            "type" => "string",
            "enum" => %w[page full_width]
          },

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

          "rows" => {
            "type" => "array",
            "items" => {
              "type" => "array",
              "minItems" => 1,
              "items" => {
                "$ref" => "#/$defs/cell"
              }
            }
          },

          "screen_config" => {
            "type" => "object",
            "additionalProperties" => false,
            "properties" => {
              "mode" => {
                "$ref" => "#/$defs/screen_mode"
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
                "$ref" => "#/$defs/commit_mode"
              },
              "title" => {
                "type" => "string"
              }
            }
          },

          "screen" => {
            "type" => "object",
            "required" => [ "id" ],
            "additionalProperties" => false,
            "properties" => {
              "id" => {
                "type" => "string",
                "minLength" => 1
              },
              "title" => {
                "type" => "string"
              },
              "mode" => {
                "$ref" => "#/$defs/screen_mode"
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
                "$ref" => "#/$defs/commit_mode"
              },
              "root_binding" => {
                "$ref" => "#/$defs/binding"
              },
              "subform" => {
                "type" => "string",
                "minLength" => 1
              },
              "rows" => {
                "$ref" => "#/$defs/rows"
              }
            }
          },

          "subform" => {
            "type" => "object",
            "required" => %w[id rows],
            "additionalProperties" => false,
            "properties" => {
              "id" => {
                "type" => "string",
                "minLength" => 1
              },
              "root_binding" => {
                "$ref" => "#/$defs/binding"
              },
              "rows" => {
                "$ref" => "#/$defs/rows"
              }
            }
          },

          "collection_binding" => {
            "type" => "object",
            "required" => [ "kind" ],
            "additionalProperties" => false,
            "properties" => {
              "kind" => {
                "type" => "string",
                "enum" => %w[property value_label none]
              },
              "name" => {
                "type" => "string",
                "minLength" => 1
              }
            }
          },

          "collection" => {
            "type" => "object",
            "additionalProperties" => false,
            "properties" => {
              "behavior" => {
                "type" => "string",
                "enum" => %w[list_open]
              },
              "presentation" => {
                "type" => "string",
                "enum" => %w[cards list table]
              },
              "creation" => {
                "type" => "string",
                "enum" => %w[append_and_open inline_blank_form new_screen]
              },
              "navigation" => {
                "type" => "string",
                "enum" => %w[open_item]
              },
              "delete" => {
                "type" => "string",
                "enum" => %w[disabled enabled]
              },
              "reorder" => {
                "type" => "string",
                "enum" => %w[disabled enabled]
              },
              "item_screen" => {
                "type" => "string",
                "minLength" => 1
              },
              "item_title" => {
                "$ref" => "#/$defs/collection_binding"
              },
              "item_subtitle" => {
                "$ref" => "#/$defs/collection_binding"
              }
            }
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
              },
              "help" => {
                "type" => "string"
              },
              "placeholder" => {
                "type" => "string"
              },
              "display" => {
                "type" => "object",
                "additionalProperties" => false,
                "properties" => {
                  "compact" => {
                    "type" => "boolean"
                  },
                  "readonly" => {
                    "type" => "boolean"
                  }
                }
              },
              "collection" => {
                "$ref" => "#/$defs/collection"
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
              "commit_mode" => {
                "$ref" => "#/$defs/commit_mode"
              },
              "message_mode" => {
                "type" => "string",
                "enum" => %w[hidden inline_optional inline_required]
              }
            }
          },

          "navigation_cell" => {
            "type" => "object",
            "required" => %w[kind target_screen],
            "additionalProperties" => false,
            "properties" => {
              "kind" => {
                "type" => "string",
                "const" => "navigation"
              },
              "target_screen" => {
                "type" => "string",
                "minLength" => 1
              },
              "label" => {
                "type" => "string"
              },
              "span" => {
                "type" => "integer",
                "minimum" => 1
              }
            }
          },

          "cell" => {
            "oneOf" => [
              { "$ref" => "#/$defs/field_cell" },
              { "$ref" => "#/$defs/navigation_cell" },
              { "$ref" => "#/$defs/commit_cell" }
            ]
          }
        }
      }
    end
  end
end
