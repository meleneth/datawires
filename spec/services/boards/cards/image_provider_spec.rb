# frozen_string_literal: true

require "rails_helper"

RSpec.describe Boards::Cards::ImageProvider do
  it "validates and projects implementation evidence without special controller handling" do
    config = { "src" => "/demo/fairlanes/runtime-overview.png", "alt" => "Fairlanes battle UI",
               "caption" => "Local debug executable" }
    card = Boards::Projection::Card.new(id: "runtime", kind: "image", title: "Runtime", description: "", config:)
    result = described_class.new(board: create(:board), card:, actor: nil).call

    expect(described_class.validate(config)).to be_empty
    expect(result).to have_attributes(status: "available", partial: "boards/cards/image")
    expect(result.data).to eq(config)
  end
end
