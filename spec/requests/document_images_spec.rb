# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Document images", type: :request do
  it "serves versioned image bytes from a visible domain" do
    document = create(:document, :with_plain_head_revision,
      head_body: { "content_type" => "image/png", "data" => Base64.strict_encode64("png bytes"), "alt" => "Demo" })

    get document_image_path(document)

    expect(response).to have_http_status(:ok)
    expect(response.media_type).to eq("image/png")
    expect(response.body).to eq("png bytes")
  end

  it "rejects invalid image documents" do
    document = create(:document, :with_plain_head_revision, head_body: { "content_type" => "text/html", "data" => "bad" })

    get document_image_path(document)

    expect(response).to have_http_status(:not_found)
  end
end
