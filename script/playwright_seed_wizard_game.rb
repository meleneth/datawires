# frozen_string_literal: true

require "json"
require "fileutils"

require Rails.root.join("db", "seeds", "private_mud_demo")

domain = Seeds::PrivateMudDemo.seed!
choice_schema = domain.documents.find_by!(key: "mud-choice-room")
start_room = domain.documents.find_by!(key: "wizard-gate")
view_affordance = choice_schema.schema_wrapper.view_affordances.order(:title).first!

path = Rails.application.routes.url_helpers.document_view_affordance_path(start_room, view_affordance)

FileUtils.mkdir_p(Rails.root.join("tmp", "playwright"))
File.write(
  Rails.root.join("tmp", "playwright", "wizard_game.json"),
  JSON.pretty_generate(
    "startPath" => path,
    "safeChoices" => [
      "Touch the moon rune",
      "Step into the listening mirror",
      "Claim the white star"
    ]
  )
)
