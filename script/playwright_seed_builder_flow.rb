# frozen_string_literal: true

require "json"
require "fileutils"
require "ostruct"

actor = User.find_or_create_by!(name: "Playwright")
domain = Domain.find_or_create_by!(name: "Playwright Builder Demo")

schema_body = {
  "$schema" => Document::JSON_SCHEMA_2020_12,
  "$id" => "http://playwright-builder-demo/schemas/playwright-builder-card",
  "type" => "object",
  "required" => [ "name" ],
  "properties" => {
    "name" => {
      "type" => "string",
      "title" => "Name"
    },
    "bio" => {
      "type" => "string",
      "title" => "Bio",
      "description" => "Long form profile copy."
    },
    "status" => {
      "type" => "string",
      "title" => "Status",
      "enum" => [ "draft", "published", "archived" ]
    },
    "items" => {
      "type" => "array",
      "title" => "Items",
      "items" => {
        "type" => "object",
        "properties" => {
          "name" => { "type" => "string", "title" => "Name" },
          "notes" => { "type" => "string", "title" => "Notes" }
        }
      }
    }
  }
}

schema_document = domain.documents.find_or_initialize_by(key: "playwright-builder-card")
schema_document.title = "Playwright Builder Card"
schema_document.save!

schema_revision = schema_document.revisions.create!(
  body: schema_body,
  message: "Seed Playwright builder schema",
  created_by: actor
)
schema_document.update!(head_revision: schema_revision)
schema_wrapper = SyncSchemaWrapperForDocument.call(document: schema_document)

result = if (affordance = schema_wrapper.edit_affordances.find_by(title: "Builder Flow"))
  OpenStruct.new(edit_affordance: affordance, draft: affordance.edit_document.draft_for(actor: actor))
else
  CreateEditAffordance.call(schema_wrapper: schema_wrapper, title: "Builder Flow", actor: actor)
end

initial_body = {
  "version" => 1,
  "start_screen" => "main",
  "commit_mode" => "review_screen",
  "subforms" => [],
  "screens" => [
    {
      "id" => "main",
      "title" => "Main",
      "columns" => 12,
      "default_span" => 3,
      "width" => "large",
      "rows" => []
    }
  ]
}

result.draft.update!(
  based_on_revision: result.edit_affordance.edit_document.head_revision,
  body: initial_body
)

path = Rails.application.routes.url_helpers.draft_edit_affordance_builder_path(result.draft)
FileUtils.mkdir_p(Rails.root.join("tmp", "playwright"))
File.write(
  Rails.root.join("tmp", "playwright", "builder_flow.json"),
  JSON.pretty_generate(
    "builderPath" => path
  )
)
