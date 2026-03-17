# script/create_demo_schema.rb
# frozen_string_literal: true

DOMAIN_NAME = "default"
SCHEMA_KEY = "project"

schema_body = {
  "$schema" => Document::JSON_SCHEMA_2020_12,
  "$id" => "http://datawires.test/schemas/project",
  "type" => "object",
  "required" => [ "name", "metadata" ],
  "properties" => {
    "name" => {
      "type" => "string"
    },
    "version" => {
      "type" => "number"
    },
    "metadata" => {
      "type" => "object",
      "required" => [ "owner" ],
      "properties" => {
        "owner" => {
          "type" => "string"
        },
        "created_at" => {
          "type" => "string",
          "format" => "date-time"
        },
        "tags" => {
          "type" => "array",
          "items" => {
            "type" => "string"
          }
        }
      }
    },
    "settings" => {
      "type" => "object",
      "properties" => {
        "public" => {
          "type" => "boolean"
        },
        "priority" => {
          "type" => "integer"
        },
        "thresholds" => {
          "type" => "object",
          "properties" => {
            "warning" => {
              "type" => "number"
            },
            "critical" => {
              "type" => "number"
            }
          }
        }
      }
    },
    "tasks" => {
      "type" => "array",
      "items" => {
        "type" => "object",
        "required" => [ "title" ],
        "properties" => {
          "title" => {
            "type" => "string"
          },
          "completed" => {
            "type" => "boolean"
          },
          "estimate_hours" => {
            "type" => "number"
          },
          "assignee" => {
            "type" => "object",
            "properties" => {
              "name" => {
                "type" => "string"
              },
              "id" => {
                "type" => "integer"
              }
            }
          }
        }
      }
    }
  }
}

ActiveRecord::Base.transaction do
  domain = Domain.find_or_create_by!(name: DOMAIN_NAME)
  existing = domain.documents.find_by(key: SCHEMA_KEY)
  if existing
    raise "Document with key=#{SCHEMA_KEY.inspect} already exists in domain #{DOMAIN_NAME.inspect}"
  end

  document = domain.documents.create!(
    key: SCHEMA_KEY
  )

  revision = document.revisions.create!(
    body: schema_body
  )

  document.update!(head_revision: revision)

  puts "Created schema document:"
  puts "  domain: #{domain.name}"
  puts "  key: #{document.key}"
  puts "  id: #{document.id}"
  puts "  revision_id: #{revision.id}"
end
