# db/seeds/edit_form_schema.rb
# frozen_string_literal: true

domain = Domain.find_or_create_by!(name: "Datawires") do |d|
  d.slug = "datawires" if d.respond_to?(:slug=)
end

schema_body = {
  "$schema" => "https://json-schema.org/draft/2020-12/schema",
  "$id" => "http://datawires/schemas/edit-form",
  "title" => "Edit Form",
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
    "field_cell" => {
      "type" => "object",
      "required" => [ "ptr" ],
      "additionalProperties" => false,
      "properties" => {
        "ptr" => {
          "type" => "string",
          "minLength" => 1
        },
        "span" => {
          "type" => "integer",
          "minimum" => 1
        },
        "widget" => {
          "type" => "string",
          "enum" => %w[text textarea select auto]
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

document = Document.find_or_initialize_by(domain: domain, key: "edit-form")

if document.new_record?
  document.save!
end

current_body = document.head_revision&.body

if current_body != schema_body
  revision = document.revisions.create!(
    body: schema_body
  )

  document.update!(head_revision: revision)
end
