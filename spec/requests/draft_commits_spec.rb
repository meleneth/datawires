# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Draft commits", type: :request do
  describe "POST /drafts/:draft_id/commit" do
    it "blocks unsupported schema declarations until confirmed" do
      draft = create(
        :draft,
        body: {
          "$schema" => "https://json-schema.org/draft/1999-09/schema",
          "$id" => "http://example.test/schemas/old",
          "type" => "object"
        }
      )

      post draft_commit_path(draft), params: {
        commit: {
          message: "commit old schema"
        }
      }

      expect(response).to have_http_status(:unprocessable_entity)
      expect(Draft.exists?(draft.id)).to be(true)
      expect(draft.document.reload.head_revision).to be_nil
      expect(response.body).to include("Unsupported schema declaration")
    end

    it "publishes unsupported schema declarations once confirmed" do
      draft = create(
        :draft,
        body: {
          "$schema" => "https://json-schema.org/draft/1999-09/schema",
          "$id" => "http://example.test/schemas/old",
          "type" => "object"
        }
      )

      post draft_commit_path(draft), params: {
        commit: {
          message: "commit old schema",
          confirmed_warnings: [ DraftCommitPreflight::UNSUPPORTED_SCHEMA_DECLARATION ]
        }
      }

      expect(response).to redirect_to(domain_path(draft.domain))
      expect(Draft.exists?(draft.id)).to be(false)
      expect(draft.document.reload.body["$schema"]).to eq("https://json-schema.org/draft/1999-09/schema")
    end
  end
end
