# frozen_string_literal: true

require "rails_helper"
require Rails.root.join("db/seeds/private_mud_demo")

RSpec.describe Seeds::PrivateMudDemo do
  it "seeds a deterministic private MUD demo domain" do
    described_class.seed!

    domain = Domain.find(described_class::DOMAIN_ID)
    expect(domain.name).to eq("Private MUD Demo")
    expect(domain.documents.where(key: %w[mud-room mud-character mud-item mud-world mud-choice-room]).count).to eq(5)

    atrium = domain.documents.find_by!(key: "atrium")
    guest = domain.documents.find_by!(key: "guest")
    world = domain.documents.find_by!(key: "demo-world")
    wizard_gate = domain.documents.find_by!(key: "wizard-gate")

    expect(atrium.id).to eq(described_class::DOCUMENT_IDS.fetch("atrium"))
    expect(guest.id).to eq(described_class::DOCUMENT_IDS.fetch("guest"))
    expect(world.id).to eq(described_class::DOCUMENT_IDS.fetch("demo-world"))
    expect(wizard_gate.id).to eq(described_class::DOCUMENT_IDS.fetch("wizard-gate"))
    expect(atrium.schema_document.key).to eq("mud-room")
    expect(guest.schema_document.key).to eq("mud-character")
    expect(world.schema_document.key).to eq("mud-world")
    expect(wizard_gate.schema_document.key).to eq("mud-choice-room")
    expect(atrium.body.fetch("exits").pluck("room_key")).to include("library", "workshop")
    expect(guest.body.fetch("inventory_item_keys")).to include("brass-key")

    room_view = domain.documents.find_by!(key: "mud-room").schema_wrapper.view_affordances.sole
    projection = ViewAffordances::Projection.build(document: atrium, view_affordance: room_view)
    expect(projection.renderer).to eq("mud_player")
    expect(projection.data.fetch("room")).to include("title" => "Lantern Atrium")
    expect(projection.data.fetch("exits").pluck("room_key")).to include("library", "workshop")
    expect(projection.data.fetch("characters").pluck("name")).to include("Atrium Warden", "Guest Explorer")

    character_view = domain.documents.find_by!(key: "mud-character").schema_wrapper.view_affordances.sole
    character_projection = ViewAffordances::Projection.build(document: guest, view_affordance: character_view)
    expect(character_projection.data.fetch("player")).to include("name" => "Guest Explorer")
    expect(character_projection.data.fetch("player").fetch("inventory").pluck("name")).to include("Brass Key")

    choice_view = domain.documents.find_by!(key: "mud-choice-room").schema_wrapper.view_affordances.sole
    choice_projection = ViewAffordances::Projection.build(document: wizard_gate, view_affordance: choice_view)
    expect(choice_projection.renderer).to eq("mud_choice_player")
    expect(choice_projection.data.fetch("room")).to include("title" => "Wizard's Gate")
    expect(choice_projection.data.fetch("choices").count).to eq(3)
    expect(choice_projection.data.fetch("choices").pluck("outcome")).to contain_exactly("death", "advance", "death")

    home = domain.documents.find_by!(key: "domain-home")
    expect(home.id).to eq(described_class::DOCUMENT_IDS.fetch("domain-home"))
    expect(home.schema_document.key).to eq("domain-home-page")
    expect(home.body.fetch("groups").flat_map { |group| group.fetch("links") }.pluck("title")).to include(
      "Play Lantern House",
      "Wizard's World",
      "Rooms"
    )
  end

  it "is idempotent" do
    described_class.seed!

    expect {
      described_class.seed!
    }.not_to change { [ Domain.count, Document.count, Revision.count ] }
  end
end
