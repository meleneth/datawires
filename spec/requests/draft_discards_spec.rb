# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Draft discards", type: :request do
  it "destroys an uncommitted document shell when its draft is discarded" do
    document = create(:document, head_revision: nil)
    draft = create(:draft, document:)

    expect {
      delete draft_path(draft)
    }.to change(Draft, :count).by(-1)
      .and change(Document, :count).by(-1)

    expect(response).to redirect_to(domain_path(document.domain))
  end

  it "keeps a committed document when its draft is discarded" do
    document = create(:document, :with_plain_head_revision)
    draft = create(:draft, document:)

    expect {
      delete draft_path(draft)
    }.to change(Draft, :count).by(-1)
      .and change(Document, :count).by(0)

    expect(Document.exists?(document.id)).to be(true)
  end
end
