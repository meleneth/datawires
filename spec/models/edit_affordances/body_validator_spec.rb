# frozen_string_literal: true

require "rails_helper"

RSpec.describe EditAffordances::BodyValidator do
  def validator_for(body)
    described_class.new(body)
  end

  it "accepts the current affordance DSL shape" do
    validator = validator_for(
      "version" => 1,
      "screen" => {
        "mode" => "page",
        "columns" => 12,
        "default_span" => 4,
        "commit_mode" => "review_screen"
      },
      "rows" => [
        [
          {
            "binding" => {
              "kind" => "document_ptr",
              "ptr" => "/title"
            },
            "span" => 6,
            "widget" => "textarea",
            "label" => true,
            "help" => "Short guidance for authors.",
            "placeholder" => "Write something useful"
          },
          {
            "kind" => "commit",
            "span" => 6,
            "message_mode" => "inline_optional"
          }
        ]
      ]
    )

    expect(validator).to be_valid
  end

  it "requires an explicit version" do
    validator = validator_for("rows" => [])

    expect(validator.errors).to include("version is required")
  end

  it "rejects unsupported versions" do
    validator = validator_for(
      "version" => 99,
      "rows" => []
    )

    expect(validator.errors).to include("version 99 is not supported")
  end

  it "requires rows to be an array" do
    validator = validator_for(
      "version" => 1,
      "rows" => {}
    )

    expect(validator.errors).to include("rows must be an array")
  end

  it "rejects unsupported field widgets" do
    validator = validator_for(
      "version" => 1,
      "rows" => [
        [
          {
            "binding" => {
              "kind" => "document_ptr",
              "ptr" => "/title"
            },
            "widget" => "slider"
          }
        ]
      ]
    )

    expect(validator.errors).to include(
      "rows/0/0/widget must be one of: array, auto, checkbox, number, select, text, textarea"
    )
  end

  it "rejects non-string field metadata" do
    validator = validator_for(
      "version" => 1,
      "rows" => [
        [
          {
            "binding" => {
              "kind" => "document_ptr",
              "ptr" => "/title"
            },
            "help" => [ "explain it" ],
            "placeholder" => 12
          }
        ]
      ]
    )

    expect(validator.errors).to include(
      "rows/0/0/help must be a string",
      "rows/0/0/placeholder must be a string"
    )
  end

  it "rejects unsupported cells" do
    validator = validator_for(
      "version" => 1,
      "rows" => [
        [
          {
            "kind" => "unknown"
          }
        ]
      ]
    )

    expect(validator.errors).to include("rows/0/0 must be a field or commit cell")
  end

  it "rejects missing field binding pointers" do
    validator = validator_for(
      "version" => 1,
      "rows" => [
        [
          {
            "binding" => {
              "kind" => "document_ptr"
            }
          }
        ]
      ]
    )

    expect(validator.errors).to include("rows/0/0/binding/ptr is required")
  end
end
