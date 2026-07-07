# frozen_string_literal: true

require "rails_helper"

RSpec.describe ViewAffordances::BodyValidator do
  def validator_for(body)
    described_class.new(body)
  end

  it "accepts the current timeline view DSL shape" do
    validator = validator_for(
      "version" => 1,
      "renderer" => "timeline_d3",
      "title" => "Timeline",
      "config" => {
        "schema_key" => "timeline-event",
        "relative_time_label" => "Relative time",
        "participant_kind" => "person"
      }
    )

    expect(validator).to be_valid
  end

  it "accepts the MUD player view DSL shape" do
    validator = validator_for(
      "version" => 1,
      "renderer" => "mud_player",
      "title" => "Play",
      "config" => {
        "room_schema_key" => "mud-room",
        "character_schema_key" => "mud-character",
        "item_schema_key" => "mud-item",
        "start_room_key" => "atrium"
      }
    )

    expect(validator).to be_valid
  end

  it "accepts the MUD choice player view DSL shape" do
    validator = validator_for(
      "version" => 1,
      "renderer" => "mud_choice_player",
      "title" => "Choice Play",
      "config" => {
        "choice_room_schema_key" => "mud-choice-room",
        "start_room_key" => "wizard-gate"
      }
    )

    expect(validator).to be_valid
  end

  it "requires a JSON object body" do
    validator = validator_for([])

    expect(validator.errors).to include("body must be a JSON object")
  end

  it "requires an explicit supported version" do
    missing = validator_for("renderer" => "timeline_d3")
    unsupported = validator_for("version" => 99, "renderer" => "timeline_d3")
    invalid = validator_for("version" => [], "renderer" => "timeline_d3")

    expect(missing.errors).to include("version is required")
    expect(unsupported.errors).to include("version 99 is not supported")
    expect(invalid.errors).to include("version must be an integer")
  end

  it "requires a supported renderer" do
    missing = validator_for("version" => 1)
    unsupported = validator_for("version" => 1, "renderer" => "force_graph")

    expect(missing.errors).to include("renderer is required")
    expect(unsupported.errors).to include("renderer must be one of: timeline_d3, mud_player, mud_choice_player")
  end

  it "validates MUD player renderer metadata" do
    validator = validator_for(
      "version" => 1,
      "renderer" => "mud_player",
      "config" => {
        "room_schema_key" => [],
        "character_schema_key" => 12,
        "item_schema_key" => false,
        "start_room_key" => {}
      }
    )

    expect(validator.errors).to include(
      "config/room_schema_key must be a string",
      "config/character_schema_key must be a string",
      "config/item_schema_key must be a string",
      "config/start_room_key must be a string"
    )
  end

  it "validates MUD choice player renderer metadata" do
    validator = validator_for(
      "version" => 1,
      "renderer" => "mud_choice_player",
      "config" => {
        "choice_room_schema_key" => [],
        "start_room_key" => false
      }
    )

    expect(validator.errors).to include(
      "config/choice_room_schema_key must be a string",
      "config/start_room_key must be a string"
    )
  end

  it "validates timeline renderer metadata" do
    validator = validator_for(
      "version" => 1,
      "renderer" => "timeline_d3",
      "title" => [],
      "config" => {
        "schema_key" => 12,
        "relative_time_label" => false,
        "participant_kind" => [],
        "participant_key" => {}
      }
    )

    expect(validator.errors).to include(
      "title must be a string",
      "config/schema_key must be a string",
      "config/relative_time_label must be a string",
      "config/participant_kind must be a string",
      "config/participant_key must be a string"
    )
  end

  it "requires config to be an object when present" do
    validator = validator_for(
      "version" => 1,
      "renderer" => "timeline_d3",
      "config" => []
    )

    expect(validator.errors).to include("config must be an object")
  end
end
