# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Schema-backed document flow", type: :request do
  it "creates a schema, creates and edits a document, rejects stale commit, and syncs schema wrapper state" do
    domain = create(:domain)

    post domain_schemas_path(domain), params: {
      document: {
        key: "profile",
        title: "Profile"
      }
    }

    schema_draft = Draft.last
    schema_document = schema_draft.document

    expect(response).to redirect_to(draft_path(schema_draft))
    expect(schema_document.head_revision).to be_nil
    expect(schema_document.schema_wrapper).to be_nil

    patch add_draft_schema_properties_path(schema_draft, format: :turbo_stream), params: {
      path: "/",
      name: "name",
      property_type: "string",
      required: "1"
    }

    expect(response).to have_http_status(:ok)

    post draft_commit_path(schema_draft), params: {
      commit: {
        message: "Create profile schema"
      }
    }

    expect(response).to redirect_to(domain_path(domain))
    expect(Draft.exists?(schema_draft.id)).to be(false)
    expect(schema_document.reload.schema_wrapper).to be_present
    expect(schema_document.body.dig("properties", "name")).to eq("type" => "string")

    post schema_documents_path(schema_document.schema_wrapper)

    document_draft = Draft.last
    document = document_draft.document

    expect(response).to redirect_to(draft_path(document_draft))
    expect(document.schema_document).to eq(schema_document)
    expect(document.body).to eq({})

    patch patch_ptr_draft_path(document_draft, format: :turbo_stream), params: {
      ptr: "/name",
      value: "Ada"
    }

    expect(response).to have_http_status(:no_content)
    expect(document_draft.reload.body).to eq("name" => "Ada")

    stale_draft = create(
      :draft,
      document: document,
      created_by: create(:user),
      based_on_revision: document.head_revision,
      body: { "name" => "Stale" }
    )

    post draft_commit_path(document_draft), params: {
      commit: {
        message: "Set name"
      }
    }

    expect(response).to redirect_to(domain_path(domain))
    expect(document.reload.body).to eq("name" => "Ada")

    post draft_commit_path(stale_draft), params: {
      commit: {
        message: "Stale name"
      }
    }

    expect(response).to redirect_to(draft_path(stale_draft))
    expect(Draft.exists?(stale_draft.id)).to be(true)
    expect(document.reload.body).to eq("name" => "Ada")

    post document_draft_path(schema_document)

    schema_removal_draft = schema_document.drafts.order(:created_at).last
    schema_removal_draft.update!(body: { "title" => "No longer a schema" })

    post draft_commit_path(schema_removal_draft), params: {
      commit: {
        message: "Remove schema declaration"
      }
    }

    expect(response).to redirect_to(domain_path(domain))
    expect(schema_document.reload.schema_wrapper).to be_nil
    expect(document.reload.schema_document).to be_nil
  end
end
