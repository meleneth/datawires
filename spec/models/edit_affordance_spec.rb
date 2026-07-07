# frozen_string_literal: true

require "rails_helper"

RSpec.describe EditAffordance, type: :model do
  describe "associations" do
    it { is_expected.to belong_to(:schema_wrapper).class_name("SchemaWrapper") }
    it { is_expected.to belong_to(:edit_document).class_name("Document") }
  end

  it "defaults to private" do
    expect(create(:edit_affordance)).not_to be_public
  end

  it "scopes public edit affordances" do
    public_affordance = create(:edit_affordance, public: true)
    create(:edit_affordance, public: false)

    expect(described_class.publicly_available).to contain_exactly(public_affordance)
  end

  describe "validations" do
    subject(:edit_affordance) { build(:edit_affordance) }

    it { is_expected.to validate_presence_of(:title) }

    it "validates uniqueness of title scoped to schema_wrapper_id" do
      schema_wrapper = create(:schema_wrapper)

      create(
        :edit_affordance,
        schema_wrapper: schema_wrapper,
        title: "default"
      )

      duplicate = build(
        :edit_affordance,
        schema_wrapper: schema_wrapper,
        title: "default"
      )

      expect(duplicate).not_to be_valid
      expect(duplicate.errors[:title]).to include("has already been taken")
    end

    it "allows the same title for a different schema wrapper" do
      first_schema_wrapper = create(:schema_wrapper)
      second_schema_wrapper = create(:schema_wrapper)

      create(
        :edit_affordance,
        schema_wrapper: first_schema_wrapper,
        title: "default"
      )

      other = build(
        :edit_affordance,
        schema_wrapper: second_schema_wrapper,
        title: "default"
      )

      expect(other).to be_valid
    end
  end

  describe "custom validations" do
    let(:schema_wrapper) { create(:schema_wrapper) }
    let(:edit_document) do
      create(
        :document,
        :with_head_revision,
        head_body: {
          "version" => 1,
          "rows" => [
            [
              {
                "kind" => "commit"
              }
            ]
          ]
        }
      )
    end

    it "is valid when schema_wrapper wraps a schema document" do
      affordance = build(
        :edit_affordance,
        schema_wrapper: schema_wrapper,
        edit_document: edit_document
      )

      expect(affordance).to be_valid
    end

    it "is invalid when edit_document equals the wrapped schema document" do
      affordance = build(
        :edit_affordance,
        schema_wrapper: schema_wrapper,
        edit_document: schema_wrapper.document
      )

      expect(affordance).not_to be_valid
      expect(affordance.errors[:edit_document]).to include("must be a separate document")
    end
  end

  describe "#body" do
    it "returns the upgraded edit document head body" do
      edit_document = create(
        :document,
        :with_head_revision,
        head_body: {
          "rows" => []
        }
      )
      affordance = build(:edit_affordance, edit_document: edit_document)

      expect(affordance.body).to eq(
        "version" => 1,
        "rows" => []
      )
    end
  end

  describe "edit document body validation" do
    it "rejects invalid edit affordance document bodies" do
      edit_document = create(
        :document,
        :with_head_revision,
        head_body: {
          "version" => 1,
          "rows" => [
            [
              {
                "kind" => "unknown"
              }
            ]
          ]
        }
      )
      affordance = build(:edit_affordance, edit_document: edit_document)

      expect(affordance).not_to be_valid
      expect(affordance.errors[:edit_document]).to include(
        "rows/0/0 must be a field, navigation, or commit cell"
      )
    end
  end

  describe "#projection" do
    it "projects bespoke rows into a projection with typed cells" do
      schema_wrapper = create(
        :schema_wrapper,
        document: create(:document, :with_name_schema)
      )
      edit_document = create(
        :document,
        :with_head_revision,
        head_body: {
          "version" => 1,
          "screen" => {
            "columns" => 6
          },
          "rows" => [
            [
              {
                "binding" => {
                  "kind" => "document_ptr",
                  "ptr" => "/name"
                },
                "span" => 3,
                "help" => "Use the public display name.",
                "placeholder" => "Ada Lovelace",
                "display" => {
                  "compact" => true,
                  "readonly" => false
                }
              },
              {
                "kind" => "commit",
                "span" => 3,
                "message_mode" => "inline_optional"
              }
            ]
          ]
        }
      )
      affordance = build(
        :edit_affordance,
        schema_wrapper: schema_wrapper,
        edit_document: edit_document
      )
      draft = build(
        :draft,
        document: build(:document, schema_document: schema_wrapper.document),
        body: {}
      )
      cursor = Documents::Cursor.new(source: draft, path: "")

      projection = affordance.projection(cursor)
      cells = projection.rows.flat_map(&:cells)

      expect(projection).to be_a(EditAffordances::Projection)
      expect(projection.defaults.column_count).to eq(6)
      expect(cells.first).to be_a(EditAffordances::Cells::Field)
      expect(cells.first.help).to eq("Use the public display name.")
      expect(cells.first.placeholder).to eq("Ada Lovelace")
      expect(cells.first.display).to eq(
        "compact" => true,
        "readonly" => false
      )
      expect(cells.second).to be_a(EditAffordances::Cells::Commit)
    end

    it "projects legacy rows as a main screen for compatibility" do
      schema_wrapper = create(
        :schema_wrapper,
        document: create(:document, :with_name_schema)
      )
      edit_document = create(
        :document,
        :with_head_revision,
        head_body: {
          "version" => 1,
          "screen" => {
            "columns" => 6,
            "default_span" => 3,
            "commit_mode" => "review_screen"
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
      )
      affordance = build(
        :edit_affordance,
        schema_wrapper: schema_wrapper,
        edit_document: edit_document
      )
      draft = build(
        :draft,
        document: build(:document, schema_document: schema_wrapper.document),
        body: {}
      )
      cursor = Documents::Cursor.new(source: draft, path: "")

      projection = affordance.projection(cursor)
      screen = projection.start_screen

      expect(projection.start_screen_id).to eq("main")
      expect(projection.rows).to eq(screen.rows)
      expect(projection.screens.map(&:id)).to eq([ "main" ])
      expect(screen.defaults.column_count).to eq(6)
      expect(screen.rows.first.cells.first.span).to eq(3)
      expect(screen.commit_mode).to eq("review_screen")
    end

    it "projects multiple screens and uses the configured start screen rows" do
      schema_wrapper = create(
        :schema_wrapper,
        document: create(
          :document,
          :with_head_revision,
          head_body: {
            "$schema" => Document::JSON_SCHEMA_2020_12,
            "$id" => "http://example.test/schemas/person",
            "type" => "object",
            "properties" => {
              "name" => { "type" => "string" },
              "profile" => {
                "type" => "object",
                "properties" => {
                  "bio" => { "type" => "string" }
                }
              }
            }
          }
        )
      )
      edit_document = create(
        :document,
        :with_head_revision,
        head_body: {
          "version" => 1,
          "start_screen" => "profile",
          "screens" => [
            {
              "id" => "summary",
              "title" => "Summary",
              "columns" => 12,
              "default_span" => 6,
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
            },
            {
              "id" => "profile",
              "title" => "Profile",
              "columns" => 6,
              "default_span" => 3,
              "root_binding" => {
                "kind" => "document_ptr",
                "ptr" => "/profile"
              },
              "rows" => [
                [
                  {
                    "binding" => {
                      "kind" => "document_ptr",
                      "ptr" => "/profile/bio"
                    }
                  }
                ]
              ]
            }
          ]
        }
      )
      affordance = build(
        :edit_affordance,
        schema_wrapper: schema_wrapper,
        edit_document: edit_document
      )
      draft = build(
        :draft,
        document: build(:document, schema_document: schema_wrapper.document),
        body: {
          "profile" => {}
        }
      )
      cursor = Documents::Cursor.new(source: draft, path: "")

      projection = affordance.projection(cursor)
      active_screen = projection.start_screen

      expect(projection.start_screen_id).to eq("profile")
      expect(projection.screens.map(&:id)).to eq([ "summary", "profile" ])
      expect(active_screen.title).to eq("Profile")
      expect(active_screen.root_cursor.path.to_s).to eq("/profile")
      expect(active_screen.defaults.column_count).to eq(6)
      expect(projection.rows).to eq(active_screen.rows)
      expect(projection.rows.first.cells.first.name).to eq("bio")
      expect(projection.rows.first.cells.first.span).to eq(3)
    end

    it "projects navigation cells between screens" do
      schema_wrapper = create(
        :schema_wrapper,
        document: create(:document, :with_name_schema)
      )
      edit_document = create(
        :document,
        :with_head_revision,
        head_body: {
          "version" => 1,
          "screens" => [
            {
              "id" => "summary",
              "rows" => [
                [
                  {
                    "kind" => "navigation",
                    "target_screen" => "details",
                    "span" => 12
                  }
                ]
              ]
            },
            {
              "id" => "details",
              "title" => "Details",
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
          ]
        }
      )
      affordance = build(
        :edit_affordance,
        schema_wrapper: schema_wrapper,
        edit_document: edit_document
      )
      draft = build(
        :draft,
        document: build(:document, schema_document: schema_wrapper.document),
        body: {}
      )
      cursor = Documents::Cursor.new(source: draft, path: "")

      summary_projection = affordance.projection(cursor)
      details_projection = affordance.projection(cursor, screen_id: "details")
      navigation = summary_projection.rows.first.cells.first

      expect(navigation).to be_a(EditAffordances::Cells::Navigation)
      expect(navigation.target_screen_id).to eq("details")
      expect(navigation.label).to eq("Details")
      expect(navigation.span).to eq(12)
      expect(details_projection.rows.first.cells.first.name).to eq("name")
    end

    it "resolves global, screen, and cell commit modes" do
      schema_wrapper = create(
        :schema_wrapper,
        document: create(:document, :with_name_schema)
      )
      edit_document = create(
        :document,
        :with_head_revision,
        head_body: {
          "version" => 1,
          "commit_mode" => "immediate",
          "screens" => [
            {
              "id" => "summary",
              "rows" => [
                [
                  {
                    "kind" => "commit"
                  }
                ]
              ]
            },
            {
              "id" => "review",
              "commit_mode" => "review_screen",
              "rows" => [
                [
                  {
                    "kind" => "commit",
                    "commit_mode" => "immediate"
                  }
                ]
              ]
            }
          ]
        }
      )
      affordance = build(
        :edit_affordance,
        schema_wrapper: schema_wrapper,
        edit_document: edit_document
      )
      draft = build(
        :draft,
        document: build(:document, schema_document: schema_wrapper.document),
        body: {}
      )
      cursor = Documents::Cursor.new(source: draft, path: "")

      summary_projection = affordance.projection(cursor)
      review_projection = affordance.projection(cursor, screen_id: "review")

      expect(summary_projection.start_screen.commit_mode).to eq("immediate")
      expect(summary_projection.rows.first.cells.first.commit_mode).to eq("immediate")
      expect(review_projection.start_screen.commit_mode).to eq("review_screen")
      expect(review_projection.rows.first.cells.first.commit_mode).to eq("immediate")
    end

    it "substitutes path variables for collection item screens" do
      schema_wrapper = create(
        :schema_wrapper,
        document: create(
          :document,
          :with_head_revision,
          head_body: {
            "$schema" => Document::JSON_SCHEMA_2020_12,
            "$id" => "http://example.test/schemas/list",
            "type" => "object",
            "properties" => {
              "items" => {
                "type" => "array",
                "items" => {
                  "type" => "object",
                  "properties" => {
                    "name" => { "type" => "string" }
                  }
                }
              }
            }
          }
        )
      )
      edit_document = create(
        :document,
        :with_head_revision,
        head_body: {
          "version" => 1,
          "screens" => [
            {
              "id" => "item",
              "root_binding" => {
                "kind" => "document_ptr",
                "ptr" => "/items/:index"
              },
              "rows" => [
                [
                  {
                    "binding" => {
                      "kind" => "document_ptr",
                      "ptr" => "/items/:index/name"
                    }
                  }
                ]
              ]
            }
          ]
        }
      )
      affordance = build(
        :edit_affordance,
        schema_wrapper: schema_wrapper,
        edit_document: edit_document
      )
      draft = build(
        :draft,
        document: build(:document, schema_document: schema_wrapper.document),
        body: {
          "items" => [
            { "name" => "Ink" }
          ]
        }
      )
      cursor = Documents::Cursor.new(source: draft, path: "/items/0")

      projection = affordance.projection(cursor, screen_id: "item")
      screen = projection.start_screen
      cell = projection.rows.first.cells.first

      expect(screen.root_cursor.path.to_s).to eq("/items/0")
      expect(cell.cursor.path.to_s).to eq("/items/0/name")
      expect(cell.name).to eq("name")
    end

    it "projects a named subform relative to an object screen root" do
      schema_wrapper = create(
        :schema_wrapper,
        document: create(
          :document,
          :with_head_revision,
          head_body: {
            "$schema" => Document::JSON_SCHEMA_2020_12,
            "$id" => "http://example.test/schemas/person",
            "type" => "object",
            "properties" => {
              "profile" => {
                "type" => "object",
                "properties" => {
                  "name" => { "type" => "string" },
                  "bio" => { "type" => "string" }
                }
              }
            }
          }
        )
      )
      edit_document = create(
        :document,
        :with_head_revision,
        head_body: {
          "version" => 1,
          "subforms" => [
            {
              "id" => "profile_fields",
              "rows" => [
                [
                  {
                    "binding" => {
                      "kind" => "document_ptr",
                      "ptr" => "/name"
                    }
                  },
                  {
                    "binding" => {
                      "kind" => "document_ptr",
                      "ptr" => "/bio"
                    }
                  }
                ]
              ]
            }
          ],
          "screens" => [
            {
              "id" => "profile",
              "root_binding" => {
                "kind" => "document_ptr",
                "ptr" => "/profile"
              },
              "subform" => "profile_fields"
            }
          ]
        }
      )
      affordance = build(
        :edit_affordance,
        schema_wrapper: schema_wrapper,
        edit_document: edit_document
      )
      draft = build(
        :draft,
        document: build(:document, schema_document: schema_wrapper.document),
        body: {
          "profile" => {}
        }
      )
      cursor = Documents::Cursor.new(source: draft, path: "")

      projection = affordance.projection(cursor, screen_id: "profile")
      cells = projection.rows.flat_map(&:cells)

      expect(projection.start_screen.root_cursor.path.to_s).to eq("/profile")
      expect(cells.map { |cell| cell.cursor.path.to_s }).to eq([ "/profile/name", "/profile/bio" ])
    end

    it "reuses a named subform for a collection item screen" do
      schema_wrapper = create(
        :schema_wrapper,
        document: create(
          :document,
          :with_head_revision,
          head_body: {
            "$schema" => Document::JSON_SCHEMA_2020_12,
            "$id" => "http://example.test/schemas/list",
            "type" => "object",
            "properties" => {
              "items" => {
                "type" => "array",
                "items" => {
                  "type" => "object",
                  "properties" => {
                    "name" => { "type" => "string" },
                    "quantity" => { "type" => "integer" }
                  }
                }
              }
            }
          }
        )
      )
      edit_document = create(
        :document,
        :with_head_revision,
        head_body: {
          "version" => 1,
          "subforms" => [
            {
              "id" => "item_fields",
              "rows" => [
                [
                  {
                    "binding" => {
                      "kind" => "document_ptr",
                      "ptr" => "/name"
                    }
                  },
                  {
                    "binding" => {
                      "kind" => "document_ptr",
                      "ptr" => "/quantity"
                    }
                  }
                ]
              ]
            }
          ],
          "screens" => [
            {
              "id" => "item",
              "root_binding" => {
                "kind" => "document_ptr",
                "ptr" => "/items/:index"
              },
              "subform" => "item_fields"
            }
          ]
        }
      )
      affordance = build(
        :edit_affordance,
        schema_wrapper: schema_wrapper,
        edit_document: edit_document
      )
      draft = build(
        :draft,
        document: build(:document, schema_document: schema_wrapper.document),
        body: {
          "items" => [
            { "name" => "Ink", "quantity" => 2 }
          ]
        }
      )
      cursor = Documents::Cursor.new(source: draft, path: "/items/0")

      projection = affordance.projection(cursor, screen_id: "item")
      cells = projection.rows.flat_map(&:cells)

      expect(projection.start_screen.root_cursor.path.to_s).to eq("/items/0")
      expect(cells.map { |cell| cell.cursor.path.to_s }).to eq([ "/items/0/name", "/items/0/quantity" ])
    end

    it "projects array fields with explicit collection config" do
      schema_wrapper = create(
        :schema_wrapper,
        document: create(
          :document,
          :with_head_revision,
          head_body: {
            "$schema" => Document::JSON_SCHEMA_2020_12,
            "$id" => "http://example.test/schemas/list",
            "type" => "object",
            "properties" => {
              "items" => {
                "type" => "array",
                "items" => {
                  "type" => "object",
                  "properties" => {
                    "name" => { "type" => "string" },
                    "quantity" => { "type" => "integer" }
                  }
                }
              }
            }
          }
        )
      )
      edit_document = create(
        :document,
        :with_head_revision,
        head_body: {
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
                  "behavior" => "list_open",
                  "presentation" => "list",
                  "creation" => "new_screen",
                  "navigation" => "open_item",
                  "delete" => "disabled",
                  "reorder" => "disabled",
                  "item_title" => {
                    "kind" => "property",
                    "name" => "name"
                  },
                  "item_subtitle" => {
                    "kind" => "property",
                    "name" => "quantity"
                  }
                }
              }
            ]
          ]
        }
      )
      affordance = build(
        :edit_affordance,
        schema_wrapper: schema_wrapper,
        edit_document: edit_document
      )
      draft = build(
        :draft,
        document: build(:document, schema_document: schema_wrapper.document),
        body: {}
      )
      cursor = Documents::Cursor.new(source: draft, path: "")

      cell = affordance.projection(cursor).rows.first.cells.first

      expect(cell).to be_a(EditAffordances::Cells::Array)
      expect(cell.collection.behavior).to eq("list_open")
      expect(cell.collection.presentation).to eq("list")
      expect(cell.collection.creation).to eq("new_screen")
      expect(cell.collection.navigation).to eq("open_item")
      expect(cell.collection.delete_policy).to eq("disabled")
      expect(cell.collection.reorder_policy).to eq("disabled")
      expect(cell.collection.item_title).to eq(
        "kind" => "property",
        "name" => "name"
      )
      expect(cell.collection.item_subtitle).to eq(
        "kind" => "property",
        "name" => "quantity"
      )
    end

    it "uses screen default_span when projected cells omit spans" do
      schema_wrapper = create(
        :schema_wrapper,
        document: create(:document, :with_name_schema)
      )
      edit_document = create(
        :document,
        :with_head_revision,
        head_body: {
          "version" => 1,
          "screen" => {
            "columns" => 12,
            "default_span" => 5
          },
          "rows" => [
            [
              {
                "binding" => {
                  "kind" => "document_ptr",
                  "ptr" => "/name"
                }
              },
              {
                "kind" => "commit"
              }
            ]
          ]
        }
      )
      affordance = build(
        :edit_affordance,
        schema_wrapper: schema_wrapper,
        edit_document: edit_document
      )
      draft = build(
        :draft,
        document: build(:document, schema_document: schema_wrapper.document),
        body: {}
      )
      cursor = Documents::Cursor.new(source: draft, path: "")

      cells = affordance.projection(cursor).rows.flat_map(&:cells)

      expect(cells.map(&:span)).to eq([ 5, 5 ])
    end

    it "projects screen width into defaults" do
      schema_wrapper = create(
        :schema_wrapper,
        document: create(:document, :with_name_schema)
      )
      edit_document = create(
        :document,
        :with_head_revision,
        head_body: {
          "version" => 1,
          "screens" => [
            {
              "id" => "main",
              "width" => "full",
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
          ]
        }
      )
      affordance = build(
        :edit_affordance,
        schema_wrapper: schema_wrapper,
        edit_document: edit_document
      )
      draft = build(
        :draft,
        document: build(:document, schema_document: schema_wrapper.document),
        body: {}
      )
      cursor = Documents::Cursor.new(source: draft, path: "")

      projection = affordance.projection(cursor)

      expect(projection.defaults.width).to eq("full")
      expect(projection.start_screen.width).to eq("full")
    end

    it "projects invalid authoring cells into diagnostics and inert cells" do
      schema_wrapper = create(
        :schema_wrapper,
        document: create(:document, :with_name_schema)
      )
      edit_document = create(
        :document,
        :with_head_revision,
        head_body: {
          "version" => 1,
          "rows" => [
            [
              {
                "kind" => "unknown",
                "span" => 12
              }
            ]
          ]
        }
      )
      affordance = build(
        :edit_affordance,
        schema_wrapper: schema_wrapper,
        edit_document: edit_document
      )
      draft = build(
        :draft,
        document: build(:document, schema_document: schema_wrapper.document),
        body: {}
      )
      cursor = Documents::Cursor.new(source: draft, path: "")

      projection = affordance.projection(cursor, mode: :authoring)
      invalid_cell = projection.rows.first.cells.first

      expect(invalid_cell).to be_a(EditAffordances::Cells::Invalid)
      expect(invalid_cell.diagnostic.message).to include("unsupported edit affordance cell")
      expect(projection.diagnostics).to contain_exactly(invalid_cell.diagnostic)
    end

    it "falls back to generated projection for invalid bespoke cells in runtime mode" do
      schema_wrapper = create(
        :schema_wrapper,
        document: create(:document, :with_name_schema)
      )
      edit_document = create(
        :document,
        :with_head_revision,
        head_body: {
          "version" => 1,
          "rows" => [
            [
              {
                "kind" => "unknown"
              }
            ]
          ]
        }
      )
      affordance = build(
        :edit_affordance,
        schema_wrapper: schema_wrapper,
        edit_document: edit_document
      )
      draft = build(
        :draft,
        document: build(:document, schema_document: schema_wrapper.document),
        body: {}
      )
      cursor = Documents::Cursor.new(source: draft, path: "")

      projection = affordance.projection(cursor)

      expect(projection.rows.flat_map(&:cells).map(&:name)).to eq([ "name" ])
      expect(projection.diagnostics.first.message).to include("Fell back to generated editor")
      expect(projection.diagnostics.first.message).to include("unsupported edit affordance cell")
    end

    it "falls back to generated projection for unsupported affordance versions in runtime mode" do
      schema_wrapper = create(
        :schema_wrapper,
        document: create(:document, :with_name_schema)
      )
      edit_document = create(
        :document,
        :with_head_revision,
        head_body: {
          "version" => 99,
          "rows" => []
        }
      )
      affordance = build(
        :edit_affordance,
        schema_wrapper: schema_wrapper,
        edit_document: edit_document
      )
      draft = build(
        :draft,
        document: build(:document, schema_document: schema_wrapper.document),
        body: {}
      )
      cursor = Documents::Cursor.new(source: draft, path: "")

      projection = affordance.projection(cursor)

      expect(projection.rows.flat_map(&:cells).map(&:name)).to eq([ "name" ])
      expect(projection.diagnostics.first.message).to include("unsupported edit affordance version")
    end

    it "raises unsupported affordance versions in authoring mode" do
      schema_wrapper = create(
        :schema_wrapper,
        document: create(:document, :with_name_schema)
      )
      edit_document = create(
        :document,
        :with_head_revision,
        head_body: {
          "version" => 99,
          "rows" => []
        }
      )
      affordance = build(
        :edit_affordance,
        schema_wrapper: schema_wrapper,
        edit_document: edit_document
      )
      draft = build(
        :draft,
        document: build(:document, schema_document: schema_wrapper.document),
        body: {}
      )
      cursor = Documents::Cursor.new(source: draft, path: "")

      expect {
        affordance.projection(cursor, mode: :authoring)
      }.to raise_error(EditAffordances::Versions::UnsupportedVersionError)
    end
  end
end
