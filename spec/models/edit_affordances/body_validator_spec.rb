# frozen_string_literal: true

require "rails_helper"

RSpec.describe EditAffordances::BodyValidator do
  def validator_for(body)
    described_class.new(body)
  end

  it "accepts the current affordance DSL shape" do
    validator = validator_for(
      "version" => 1,
      "commit_mode" => "review_screen",
      "width" => "large",
      "screen" => {
        "mode" => "page",
        "columns" => 12,
        "default_span" => 4,
        "width" => "medium",
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
            "placeholder" => "Write something useful",
            "display" => {
              "compact" => true,
              "readonly" => false
            },
            "collection" => {
              "behavior" => "list_open",
              "presentation" => "list",
              "creation" => "new_screen",
              "navigation" => "open_item",
              "delete" => "enabled",
              "reorder" => "enabled",
              "item_title" => {
                "kind" => "property",
                "name" => "name"
              },
              "item_subtitle" => {
                "kind" => "reference_label",
                "schema_key_property" => "kind",
                "key_property" => "key",
                "index_type" => "identity",
                "index_key" => "document_key"
              }
            }
          },
          {
            "kind" => "commit",
            "span" => 6,
            "commit_mode" => "immediate",
            "message_mode" => "inline_optional"
          },
          {
            "binding" => {
              "kind" => "document_ptr",
              "ptr" => "/members"
            },
            "widget" => "array",
            "item_rows" => [
              [
                {
                  "binding" => {
                    "kind" => "document_ptr",
                    "ptr" => "/person_key"
                  },
                  "widget" => "reference",
                  "reference" => {
                    "schema_key_from" => "/kind",
                    "index_type" => "identity",
                    "index_key" => "document_key"
                  }
                }
              ]
            ]
          }
        ]
      ]
    )

    expect(validator).to be_valid
  end

  it "accepts configured index definitions" do
    validator = validator_for(
      "version" => 1,
      "rows" => [],
      "indexes" => [
        {
          "index_type" => "timeline_participant",
          "source" => {
            "ptr" => "/participants",
            "each" => true
          },
          "key" => {
            "ptr" => "/kind"
          },
          "value" => {
            "ptr" => "/key"
          },
          "label" => {
            "root_ptr" => "/title"
          },
          "condition" => {
            "all" => [
              {
                "value" => {
                  "root_ptr" => "/event_type"
                },
                "in" => %w[party_join party_leave]
              },
              {
                "value" => {
                  "ptr" => "/kind"
                },
                "equals" => "person"
              }
            ]
          },
          "metadata" => {
            "change" => {
              "root_ptr" => "/event_type",
              "transform" => {
                "strip_prefix" => "party_"
              }
            }
          }
        }
      ]
    )

    expect(validator).to be_valid
  end

  it "validates configured index definitions" do
    validator = validator_for(
      "version" => 1,
      "rows" => [],
      "indexes" => [
        {
          "index_type" => "",
          "source" => {
            "ptr" => [],
            "each" => "yes"
          },
          "value" => [],
          "label" => {},
          "condition" => {
            "all" => false,
            "value" => [],
            "in" => false
          },
          "metadata" => {
            "bad" => []
          }
        }
      ]
    )

    expect(validator.errors).to include(
      "indexes/0/index_type is required",
      "indexes/0/source/ptr must be a string",
      "indexes/0/source/each must be a boolean",
      "indexes/0/value must be an object",
      "indexes/0/label must include ptr, root_ptr, or literal",
      "indexes/0/condition/all must be an array",
      "indexes/0/condition/value must be an object",
      "indexes/0/condition/in must be an array",
      "indexes/0/metadata/bad must be an object"
    )
  end

  it "accepts a multi-screen affordance DSL shape" do
    validator = validator_for(
      "version" => 1,
      "start_screen" => "details",
      "screens" => [
        {
          "id" => "summary",
          "title" => "Summary",
          "mode" => "page",
          "columns" => 12,
          "default_span" => 6,
          "width" => "full",
          "commit_mode" => "review_screen",
          "rows" => [
            [
              {
                "binding" => {
                  "kind" => "document_ptr",
                  "ptr" => "/title"
                },
                "widget" => "text"
              },
              {
                "kind" => "navigation",
                "target_screen" => "details",
                "label" => "Details"
              }
            ]
          ]
        },
        {
          "id" => "details",
          "title" => "Details",
          "root_binding" => {
            "kind" => "document_ptr",
            "ptr" => "/details"
          },
          "rows" => [
            [
              {
                "kind" => "commit",
                "message_mode" => "inline_optional"
              }
            ]
          ]
        }
      ]
    )

    expect(validator).to be_valid
  end

  it "rejects invalid widths and spans outside the supported range" do
    validator = validator_for(
      "version" => 1,
      "width" => "huge",
      "screen" => {
        "default_span" => 13,
        "width" => "tiny"
      },
      "rows" => [
        [
          {
            "binding" => {
              "kind" => "document_ptr",
              "ptr" => "/name"
            },
            "span" => 0
          },
          {
            "kind" => "commit",
            "span" => 99
          }
        ]
      ]
    )

    expect(validator.errors).to include(
      "width must be one of: narrow, medium, large, full",
      "screen.default_span must be between 1 and 12",
      "screen.width must be one of: narrow, medium, large, full",
      "rows/0/0/span must be a positive integer",
      "rows/0/1/span must be between 1 and 12"
    )
  end

  it "accepts inline named subforms reused by screens" do
    validator = validator_for(
      "version" => 1,
      "subforms" => [
        {
          "id" => "item_fields",
          "root_binding" => {
            "kind" => "document_ptr",
            "ptr" => "/items/:index"
          },
          "rows" => [
            [
              {
                "binding" => {
                  "kind" => "document_ptr",
                  "ptr" => "/name"
                }
              }
            ]
          ]
        }
      ],
      "screens" => [
        {
          "id" => "item",
          "subform" => "item_fields"
        }
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

  it "validates screen definitions" do
    validator = validator_for(
      "version" => 1,
      "start_screen" => "missing",
      "screens" => [
        {
          "id" => "summary",
          "title" => 12,
          "columns" => 0,
          "root_binding" => {
            "kind" => "document_ptr"
          },
          "rows" => [
            []
          ]
        },
        {
          "id" => "summary",
          "rows" => {}
        },
        "nope"
      ]
    )

    expect(validator.errors).to include(
      "screens/0/title must be a string",
      "screens/0/columns must be a positive integer",
      "screens/0/root_binding/ptr is required",
      "screens/0/rows/0 must contain at least one cell",
      "screens/1/rows must be an array",
      "screens/2 must be an object",
      "screens id \"summary\" must be unique",
      "start_screen must match a screen id"
    )
  end

  it "validates subform definitions" do
    validator = validator_for(
      "version" => 1,
      "subforms" => [
        {
          "id" => "details",
          "root_binding" => {
            "kind" => "document_ptr"
          },
          "rows" => {}
        },
        {
          "id" => "details",
          "rows" => [
            []
          ]
        },
        "nope"
      ],
      "screens" => [
        {
          "id" => "summary",
          "subform" => "missing"
        },
        {
          "id" => "details",
          "subform" => 12
        }
      ]
    )

    expect(validator.errors).to include(
      "subforms/0/root_binding/ptr is required",
      "subforms/0/rows must be an array",
      "subforms/1/rows/0 must contain at least one cell",
      "subforms/2 must be an object",
      "subforms id \"details\" must be unique",
      "screens/0/subform must match a subform id",
      "screens/1/subform must be a string"
    )
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
      "rows/0/0/widget must be one of: array, auto, base64_image, checkbox, number, reference, select, text, textarea"
    )
  end

  it "accepts base64 image widgets" do
    body = {
      "version" => 1,
      "rows" => [
        [
          {
            "binding" => {
              "kind" => "document_ptr",
              "ptr" => "/thumbnail"
            },
            "widget" => "base64_image"
          }
        ]
      ]
    }

    expect(described_class.new(body)).to be_valid
  end

  it "accepts reference widgets with lookup configuration" do
    body = {
      "version" => 1,
      "rows" => [
        [
          {
            "binding" => {
              "kind" => "document_ptr",
              "ptr" => "/person_key"
            },
            "widget" => "reference",
            "reference" => {
              "schema_key" => "person",
              "index_type" => "identity",
              "index_key" => "document_key",
              "placeholder" => "Select person"
            }
          }
        ]
      ]
    }

    expect(described_class.new(body)).to be_valid
  end

  it "validates reference widget configuration" do
    body = {
      "version" => 1,
      "rows" => [
        [
          {
            "binding" => {
              "kind" => "document_ptr",
              "ptr" => "/person_key"
            },
            "widget" => "reference",
            "reference" => {
              "schema_key" => 12,
              "schema_key_from" => [],
              "index_type" => false,
              "index_key" => {},
              "placeholder" => []
            }
          }
        ]
      ]
    }

    expect(described_class.new(body).errors).to include(
      "rows/0/0/reference/schema_key must be a string",
      "rows/0/0/reference/schema_key_from must be a string",
      "rows/0/0/reference/index_type must be a string",
      "rows/0/0/reference/index_key must be a string",
      "rows/0/0/reference/placeholder must be a string"
    )
  end

  it "rejects invalid commit modes" do
    validator = validator_for(
      "version" => 1,
      "commit_mode" => "later",
      "rows" => [
        [
          {
            "kind" => "commit",
            "commit_mode" => "modal"
          }
        ]
      ]
    )

    expect(validator.errors).to include(
      "commit_mode must be one of: immediate, review_screen",
      "rows/0/0/commit_mode must be one of: immediate, review_screen"
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

  it "rejects invalid field display options" do
    validator = validator_for(
      "version" => 1,
      "rows" => [
        [
          {
            "binding" => {
              "kind" => "document_ptr",
              "ptr" => "/title"
            },
            "display" => {
              "compact" => "yes",
              "readonly" => nil
            }
          }
        ],
        [
          {
            "binding" => {
              "kind" => "document_ptr",
              "ptr" => "/summary"
            },
            "display" => true
          }
        ]
      ]
    )

    expect(validator.errors).to include(
      "rows/0/0/display/compact must be a boolean",
      "rows/0/0/display/readonly must be a boolean",
      "rows/1/0/display must be an object"
    )
  end

  it "rejects invalid collection config" do
    validator = validator_for(
      "version" => 1,
      "rows" => [
        [
          {
            "binding" => {
              "kind" => "document_ptr",
              "ptr" => "/items"
            },
            "widget" => "array",
            "collection" => {
              "behavior" => "mega_grid",
              "presentation" => "mosaic",
              "creation" => "side_panel",
              "navigation" => "modal",
              "delete" => "soft_delete",
              "reorder" => "drag",
              "item_screen" => 12,
              "item_title" => {
                "kind" => "property"
              },
              "item_subtitle" => {
                "kind" => "property",
                "name" => ""
              }
            }
          },
          {
            "binding" => {
              "kind" => "document_ptr",
              "ptr" => "/other_items"
            },
            "widget" => "array",
            "collection" => true
          }
        ]
      ]
    )

    expect(validator.errors).to include(
      "rows/0/0/collection/behavior must be one of: list_open",
      "rows/0/0/collection/presentation must be one of: cards, list, table",
      "rows/0/0/collection/creation must be one of: append_and_open, inline_blank_form, new_screen",
      "rows/0/0/collection/navigation must be one of: open_item",
      "rows/0/0/collection/delete must be one of: disabled, enabled",
      "rows/0/0/collection/reorder must be one of: disabled, enabled",
      "rows/0/0/collection/item_screen must be a string",
      "rows/0/0/collection/item_title/name must be a string",
      "rows/0/0/collection/item_subtitle/name must be a string",
      "rows/0/1/collection must be an object"
    )
  end

  it "validates reference label collection bindings" do
    validator = validator_for(
      "version" => 1,
      "rows" => [
        [
          {
            "binding" => {
              "kind" => "document_ptr",
              "ptr" => "/items"
            },
            "widget" => "array",
            "collection" => {
              "item_title" => {
                "kind" => "reference_label",
                "schema_key" => 12,
                "schema_key_property" => [],
                "key_property" => "",
                "index_type" => false,
                "index_key" => {}
              }
            }
          }
        ]
      ]
    )

    expect(validator.errors).to include(
      "rows/0/0/collection/item_title/schema_key must be a string",
      "rows/0/0/collection/item_title/schema_key_property must be a string",
      "rows/0/0/collection/item_title/key_property is required",
      "rows/0/0/collection/item_title/index_type must be a string",
      "rows/0/0/collection/item_title/index_key must be a string",
      "rows/0/0/collection/item_title/schema_key or rows/0/0/collection/item_title/schema_key_property is required"
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

    expect(validator.errors).to include("rows/0/0 must be a field, navigation, or commit cell")
  end

  it "rejects invalid navigation cells" do
    validator = validator_for(
      "version" => 1,
      "screens" => [
        {
          "id" => "summary",
          "rows" => [
            [
              {
                "kind" => "navigation",
                "target_screen" => "missing",
                "label" => false
              }
            ]
          ]
        },
        {
          "id" => "details",
          "rows" => [
            [
              {
                "kind" => "navigation"
              }
            ]
          ]
        }
      ]
    )

    expect(validator.errors).to include(
      "screens/0/rows/0/0/label must be a string",
      "screens/0/rows/0/0/target_screen must match a screen id",
      "screens/1/rows/0/0/target_screen is required"
    )
  end

  it "rejects collection item screens that do not match a screen id" do
    validator = validator_for(
      "version" => 1,
      "screens" => [
        {
          "id" => "summary",
          "rows" => [
            [
              {
                "binding" => {
                  "kind" => "document_ptr",
                  "ptr" => "/items"
                },
                "widget" => "array",
                "collection" => {
                  "item_screen" => "missing"
                }
              }
            ]
          ]
        },
        {
          "id" => "item",
          "rows" => [
            [
              {
                "kind" => "commit"
              }
            ]
          ]
        }
      ]
    )

    expect(validator.errors).to include(
      "screens/0/rows/0/0/collection/item_screen must match a screen id"
    )
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
