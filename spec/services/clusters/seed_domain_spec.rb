# frozen_string_literal: true

require "rails_helper"

RSpec.describe Clusters::SeedDomain do
  it "seeds the worldbuilding schemas and default edit affordances" do
    domain = create(:domain)
    actor = create(:user)

    described_class.call(domain: domain, cluster_key: Clusters::Catalog::WORLD_BUILDING, actor: actor)

    expect(domain.documents.where(key: %w[person place thing party timeline-event]).count).to eq(5)
    expect(domain.documents.find_by!(key: "thing").body).to include(
      "x-datawires-document-key" => '#{kind} - #{name}'
    )
    expect(domain.documents.find_by!(key: "place").body).to include(
      "x-datawires-document-key" => '#{kind} - #{name}'
    )
    expect(domain.reload.project_affordance).to be_nil
    home = domain.documents.find_by!(key: DomainHomeLinks::DOCUMENT_KEY)
    expect(home.schema_document.key).to eq("domain-home-page")
    expect(home.schema_document.schema_wrapper.edit_affordances.sole.title).to eq("Default")
    expect(home.body.fetch("groups").flat_map { |group| group.fetch("links") }.pluck("title")).to include(
      "People",
      "Timeline Events"
    )
    expect(DomainHomeLinks.for(domain).flat_map { |group| group.fetch("links") }.pluck("title")).to include(
      "Workspace",
      "People",
      "Timeline Events"
    )

    home_wrapper = home.schema_document.schema_wrapper
    board = home_wrapper.default_board
    expect(board).to have_attributes(title: "Worldbuilder Board", public: true)
    expect(board.board_document).to have_attributes(
      key: "worldbuilder-board",
      schema_document: domain.documents.find_by!(key: Boards::Schema::KEY)
    )
    expect(board.body).to eq(Boards::Definitions.worldbuilder_workspace)

    timeline_schema = domain.documents.find_by!(key: "timeline-event")
    timeline_body = timeline_schema.body

    expect(timeline_schema.schema_wrapper).to be_present
    expect(timeline_body.dig("properties", "relative_time")).to include(
      "type" => "integer",
      "description" => "Relative timestamp. Negative values are allowed."
    )
    expect(timeline_body.dig("properties", "event_type", "enum")).to include("party_join", "party_leave")
    expect(timeline_body.dig("properties", "participants", "items", "properties", "kind", "enum")).to eq(%w[person party])
    expect(timeline_body.dig("properties", "party_key")).to include("type" => "string")
    expect(timeline_body.dig("properties", "person_key")).to include("type" => "string")
    timeline_cells = timeline_schema.schema_wrapper.edit_affordances.sole.body.fetch("screens").first.fetch("rows").flatten
    expect(timeline_cells.find { |cell| cell["kind"] == "commit" }).to include(
      "commit_mode" => "immediate",
      "message_mode" => "inline_optional"
    )
    expect(reference_cell_for(timeline_cells, "/party_key")).to include(
      "widget" => "reference",
      "reference" => include("schema_key" => "party", "index_type" => "identity")
    )
    expect(reference_cell_for(timeline_cells, "/person_key")).to include(
      "widget" => "reference",
      "reference" => include("schema_key" => "person", "index_type" => "identity")
    )
    participants_cell = reference_cell_for(timeline_cells, "/participants")
    expect(participants_cell.dig("collection", "item_title")).to include(
      "kind" => "reference_label",
      "schema_key_property" => "kind",
      "key_property" => "key",
      "index_key" => "document_key"
    )
    expect(participants_cell.dig("collection", "item_subtitle")).to include(
      "kind" => "property",
      "name" => "notes"
    )
    expect(reference_cell_for(participants_cell.fetch("item_rows").flatten, "/key")).to include(
      "widget" => "reference",
      "reference" => include("schema_key_from" => "/kind", "index_type" => "identity")
    )
    timeline_view = timeline_schema.schema_wrapper.view_affordances.sole
    expect(timeline_view.title).to eq("Timeline")
    expect(timeline_view).to be_public
    expect(timeline_view.body).to include(
      "renderer" => "timeline_d3",
      "config" => include("schema_key" => "timeline-event")
    )

    person_schema = domain.documents.find_by!(key: "person")
    person_view = person_schema.schema_wrapper.view_affordances.sole
    expect(person_view.title).to eq("Timeline")
    expect(person_view).to be_public
    expect(person_view.body).to include(
      "renderer" => "timeline_d3",
      "config" => include(
        "schema_key" => "timeline-event",
        "participant_kind" => "person"
      )
    )

    party_schema = domain.documents.find_by!(key: "party")
    party_view = party_schema.schema_wrapper.view_affordances.sole
    expect(party_view.title).to eq("Timeline")
    expect(party_view).to be_public
    expect(party_view.body).to include(
      "renderer" => "timeline_d3",
      "config" => include(
        "schema_key" => "timeline-event",
        "participant_kind" => "party"
      )
    )
    expect(party_schema.body.dig("properties", "members", "items", "properties", "person_key")).to include(
      "type" => "string"
    )
    party_members_cell = party_schema.schema_wrapper.edit_affordances.sole.body.fetch("screens").first.fetch("rows").flatten.find do |cell|
      cell.dig("binding", "ptr") == "/members"
    end
    expect(reference_cell_for(party_members_cell.fetch("item_rows").flatten, "/person_key")).to include(
      "widget" => "reference",
      "reference" => include("schema_key" => "person", "index_type" => "identity")
    )

    SchemaWrapper.where(document: domain.documents.where(key: %w[person place thing party timeline-event])).find_each do |wrapper|
      expect(wrapper).to be_public
      affordance = wrapper.edit_affordances.sole
      expect(affordance).to be_public
      expect(affordance.title).to eq("Default")
      expect(affordance.body.fetch("screens").first.fetch("rows")).not_to be_empty
    end
  end

  it "seeds generic parliamentary engine schemas without bespoke affordances" do
    domain = create(:domain)
    actor = create(:user)

    expect {
      described_class.call(domain: domain, cluster_key: Clusters::Catalog::ROBERTS_RULES, actor: actor)
    }.to change(DomainCommit, :count).by(1)

    domain.reload
    expect(domain).to be_repository_mode
    engine_keys = [
      Bodies::Schema::KEY,
      Meetings::Schema::KEY,
      Proposals::Schema::KEY,
      Decisions::Schema::KEY,
      Agreements::Schema::KEY,
      ProceduralPolicies::Schema::KEY,
      Boards::Schema::KEY
    ]
    expect(domain.documents.where(key: engine_keys).count).to eq(engine_keys.length)
    expect(domain.documents.where(key: %w[agreement motion proceeding-event meeting-state])).to be_empty
    expect(domain.head_domain_commit).to be_present
    expect(domain.head_domain_commit.message).to eq("Seed Robert's Rules of Order cluster")
    expect(domain.head_domain_commit.domain_commit_documents.count).to eq(12)

    home = domain.documents.find_by!(key: DomainHomeLinks::DOCUMENT_KEY)
    expect(home.schema_document.key).to eq("domain-home-page")
    expect(home.schema_document.schema_wrapper.edit_affordances.sole.title).to eq("Default")
    expect(home.body.fetch("groups").flat_map { |group| group.fetch("links") }.pluck("title")).to include(
      "Agreements",
      "Bodies",
      "Meetings",
      "Proposals",
      "Decisions",
      "Repository History"
    )
    expect(DomainHomeLinks.for(domain).flat_map { |group| group.fetch("links") }.pluck("title")).to include(
      "Agreements",
      "Bodies",
      "Meetings",
      "Proposals",
      "Decisions",
      "Repository History"
    )

    SchemaWrapper.where(document: domain.documents.where(key: engine_keys)).find_each do |wrapper|
      expect(wrapper).to be_public
      expect(wrapper.edit_affordances).to be_empty
      expect(wrapper.view_affordances).to be_empty
    end

    body_wrapper = domain.documents.find_by!(key: Bodies::Schema::KEY).schema_wrapper
    board = body_wrapper.default_board
    expect(board).to have_attributes(title: "Datawires Board", public: true)
    expect(board.board_document).to have_attributes(
      key: "body-board",
      schema_document: domain.documents.find_by!(key: Boards::Schema::KEY)
    )
    expect(board.body).to eq(Boards::Definitions.body_workspace)
    administration = body_wrapper.boards.find_by!(title: "Body Administration")
    expect(administration.board_document).to have_attributes(
      key: "body-administration-board",
      schema_document: domain.documents.find_by!(key: Boards::Schema::KEY)
    )
    expect(administration.body).to eq(Boards::Definitions.body_administration)
    expect(body_wrapper.boards).to contain_exactly(board, administration)
  end

  it "seeds private MUD schemas with authoring and play affordances" do
    domain = create(:domain)
    actor = create(:user)

    described_class.call(domain: domain, cluster_key: Clusters::Catalog::PRIVATE_MUD, actor: actor)

    expect(domain.documents.where(key: %w[mud-room mud-character mud-item mud-world mud-choice-room]).count).to eq(5)
    home = domain.documents.find_by!(key: DomainHomeLinks::DOCUMENT_KEY)
    expect(home.schema_document.key).to eq("domain-home-page")
    expect(home.body.fetch("groups").flat_map { |group| group.fetch("links") }.pluck("title")).to include(
      "Rooms",
      "Characters",
      "Items",
      "Worlds",
      "Choice Rooms"
    )

    room_schema = domain.documents.find_by!(key: "mud-room")
    room_cells = room_schema.schema_wrapper.edit_affordances.sole.body.fetch("screens").first.fetch("rows").flatten
    exits_cell = room_cells.find { |cell| cell.dig("binding", "ptr") == "/exits" }
    expect(room_schema.body.dig("properties", "exits", "items", "properties", "room_key")).to include("type" => "string")
    expect(reference_cell_for(exits_cell.fetch("item_rows").flatten, "/room_key")).to include(
      "widget" => "reference",
      "reference" => include("schema_key" => "mud-room")
    )
    expect(room_schema.schema_wrapper.view_affordances.sole.body).to include(
      "renderer" => "mud_player",
      "config" => include(
        "room_schema_key" => "mud-room",
        "character_schema_key" => "mud-character",
        "item_schema_key" => "mud-item"
      )
    )
    expect(room_schema.schema_wrapper.view_affordances.sole).to be_public

    character_schema = domain.documents.find_by!(key: "mud-character")
    expect(character_schema.schema_wrapper.view_affordances.sole.title).to eq("Play")
    expect(character_schema.body.dig("properties", "inventory_item_keys", "items")).to include("type" => "string")

    world_schema = domain.documents.find_by!(key: "mud-world")
    expect(world_schema.schema_wrapper.view_affordances.sole.body.dig("config", "start_room_key")).to eq("atrium")

    choice_room_schema = domain.documents.find_by!(key: "mud-choice-room")
    expect(choice_room_schema.body.dig("properties", "choices")).to include("maxItems" => 3)
    expect(choice_room_schema.schema_wrapper.view_affordances.sole.body).to include(
      "renderer" => "mud_choice_player",
      "config" => include(
        "choice_room_schema_key" => "mud-choice-room",
        "start_room_key" => "wizard-gate"
      )
    )

    SchemaWrapper.where(document: domain.documents.where(key: %w[mud-room mud-character mud-item mud-world mud-choice-room])).find_each do |wrapper|
      expect(wrapper).to be_public
      expect(wrapper.edit_affordances.sole.title).to eq("Default")
      expect(wrapper.edit_affordances.sole).to be_public
      expect(wrapper.edit_affordances.sole.body.fetch("screens").first.fetch("rows")).not_to be_empty
    end
  end

  it "does nothing for blank clusters" do
    domain = create(:domain)

    expect {
      described_class.call(domain: domain, cluster_key: "", actor: nil)
    }.not_to change(Document, :count)
  end

  def reference_cell_for(cells, ptr)
    cells.find { |cell| cell.dig("binding", "ptr") == ptr }
  end
end
