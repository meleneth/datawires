# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Robert's Rules motion applications", type: :request do
  it "applies an adopted motion from the document page" do
    domain = seeded_domain
    motion = roberts_document(
      domain: domain,
      schema_key: "motion",
      key: "motion-adopt-rule",
      title: "Adopt speaking rule",
      body: {
        "title" => "Adopt speaking rule",
        "motion_type" => "main",
        "status" => "adopted",
        "target_agreement_key" => "speaking-rule",
        "proposed_text" => "Members may speak twice."
      }
    )

    get document_path(motion)

    expect(response).to have_http_status(:ok)
    expect(response.body).to include("Apply motion")

    expect {
      post document_motion_application_path(motion)
    }.to change(DomainCommit, :count).by(1)

    expect(response).to redirect_to(document_path(motion))
    follow_redirect!

    expect(response.body).to include("Motion was applied.")
    expect(response.body).not_to include("Apply motion")
    expect(domain.documents.find_by!(key: "speaking-rule").body).to include(
      "status" => "active",
      "body" => "Members may speak twice."
    )
    expect(domain.documents.find_by!(key: "motion-adopt-rule-applied-event")).to be_present
    expect(motion.reload.body["result"]).to eq("applied: speaking-rule")
  end

  it "redirects with an alert when the motion cannot be applied" do
    domain = seeded_domain
    motion = roberts_document(
      domain: domain,
      schema_key: "motion",
      key: "motion-pending",
      title: "Pending motion",
      body: {
        "title" => "Pending motion",
        "motion_type" => "main",
        "status" => "pending",
        "proposed_text" => "Pending text."
      }
    )

    expect {
      post document_motion_application_path(motion)
    }.not_to change(DomainCommit, :count)

    expect(response).to redirect_to(document_path(motion))
    follow_redirect!
    expect(response.body).to include("only adopted motions can be applied")
  end

  def seeded_domain
    create(:domain, name: "Rules", repository_mode: false).tap do |domain|
      Clusters::SeedDomain.call(domain: domain, cluster_key: Clusters::Catalog::ROBERTS_RULES, actor: nil)
    end
  end

  def roberts_document(domain:, schema_key:, key:, title:, body:)
    schema = domain.documents.find_by!(key: schema_key)
    document = create(:document, domain: domain, schema_document: schema, key: key, title: title)
    revision = document.revisions.create!(body: body, message: "Seed #{title}")
    document.update!(head_revision: revision)
    document
  end
end
