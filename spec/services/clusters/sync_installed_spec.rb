# frozen_string_literal: true

require "rails_helper"

RSpec.describe Clusters::SyncInstalled do
  it "upgrades an existing cluster domain while leaving unrelated domains alone" do
    installed = create(:domain, name: "oregongrye")
    unrelated = create(:domain)
    Clusters::SeedDomain.call(domain: installed, cluster_key: Clusters::Catalog::WORLD_BUILDING)

    thing_schema = installed.documents.find_by!(key: "thing")
    old_revision = thing_schema.head_revision
    old_body = thing_schema.body.except("x-datawires-document-key")
    downgraded = thing_schema.revisions.create!(body: old_body, parent_revision: old_revision)
    thing_schema.update!(head_revision: downgraded)
    place = create(
      :document,
      :with_plain_head_revision,
      domain: installed,
      schema_document: installed.documents.find_by!(key: "place"),
      key: "document-a07f2d69",
      head_body: { "kind" => "lightHouse", "name" => "Japan" }
    )

    expect {
      described_class.call
    }.not_to change { unrelated.documents.count }

    expect(thing_schema.reload.body).to include(
      "x-datawires-document-key" => '#{kind} - #{name}'
    )
    expect(place.reload.key).to eq("lightHouse - Japan")
  end
end
