# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Document drafts", type: :request do
  describe "POST /documents/:document_id/draft" do
    it "creates a draft for the document and redirects to it" do
      document = create(:document, :with_plain_head_revision)

      expect {
        post document_draft_path(document)
      }.to change(Draft, :count).by(1)

      draft = Draft.last
      expect(draft.document).to eq(document)
      expect(draft.based_on_revision).to eq(document.head_revision)
      expect(draft.body).to eq(document.body)
      expect(response).to redirect_to(draft_path(draft))
    end

    it "preserves the selected edit affordance id in the redirect" do
      document = create(:document, :with_plain_head_revision)
      edit_affordance_id = SecureRandom.uuid

      post document_draft_path(document, edit_affordance_id:)

      expect(response).to redirect_to(
        draft_path(Draft.last, edit_affordance_id:)
      )
    end
  end
end
