# frozen_string_literal: true

require "rails_helper"
require Rails.root.join("db/seeds/private_mud_demo")
require Rails.root.join("db/seeds/roberts_rules_demo")
require Rails.root.join("db/seeds/worldbuilder_demo")

RSpec.describe "Deterministic seed IDs" do
  it "keeps document IDs unique across demo domains" do
    document_ids = [
      Seeds::PrivateMudDemo::DOCUMENT_IDS,
      Seeds::RobertsRulesDemo::DOCUMENT_IDS,
      Seeds::WorldbuilderDemo::DOCUMENT_IDS
    ].flat_map(&:values)

    expect(document_ids.uniq.length).to eq(document_ids.length)
  end
end
