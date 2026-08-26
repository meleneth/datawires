# frozen_string_literal: true

require "rails_helper"

RSpec.describe Boards::Cards::ImageProvider do
  it "validates and projects implementation evidence without special controller handling" do
    board = create(:board)
    image_document = create(:document, :with_plain_head_revision, domain: board.schema_wrapper.domain,
      key: "runtime-overview", head_body: { "content_type" => "image/png", "data" => "cG5n",
                                             "alt" => "Fairlanes battle UI" })
    config = { "document_key" => image_document.key, "caption" => "Local debug executable" }
    card = Boards::Projection::Card.new(id: "runtime", kind: "image", title: "Runtime", description: "", config:)
    result = described_class.new(board:, card:, actor: nil).call

    expect(described_class.validate(config)).to be_empty
    expect(result).to have_attributes(status: "available", partial: "boards/cards/image")
    expect(result.data).to include("src" => Rails.application.routes.url_helpers.document_image_path(image_document),
      "alt" => "Fairlanes battle UI",
      "caption" => "Local debug executable")
  end
end
