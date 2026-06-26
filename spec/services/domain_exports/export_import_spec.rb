# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Domain export/import" do
  it "exports and imports a repository domain with revision and commit history intact" do
    actor = create(:user)
    domain = create(:domain, name: "Rules Archive")
    Clusters::SeedDomain.call(domain: domain, cluster_key: Clusters::Catalog::ROBERTS_RULES, actor: actor)
    first_commit = domain.reload.head_domain_commit
    agreement_schema = domain.documents.find_by!(key: "agreement")
    agreement = create(
      :document,
      domain: domain,
      key: "standing-rule",
      title: "Standing Rule",
      schema_document: agreement_schema
    )
    original_revision = agreement.revisions.create!(
      body: {
        "title" => "Standing Rule",
        "status" => "proposed",
        "body" => "Members may speak once."
      },
      message: "Draft standing rule",
      created_by: actor
    )
    agreement.update!(head_revision: original_revision)
    amended_revision = agreement.revisions.create!(
      parent_revision: original_revision,
      body: {
        "title" => "Standing Rule",
        "status" => "active",
        "body" => "Members may speak twice."
      },
      message: "Adopt standing rule",
      created_by: actor
    )
    agreement.update!(head_revision: amended_revision)
    second_commit = DomainCommits::Create.call(domain: domain, message: "Adopt standing rule", actor: actor)

    archive = DomainExports::Export.call(domain: domain)

    expect(archive.to_json).not_to match(uuid_pattern)
    imported = DomainExports::Import.call(archive: archive, name: "Rules Archive Copy")

    expect(imported).to have_attributes(
      name: "Rules Archive Copy",
      repository_mode: true
    )
    expect(imported.id).not_to eq(domain.id)
    imported_agreement = imported.documents.find_by!(key: "standing-rule")
    expect(imported_agreement.id).not_to eq(agreement.id)
    expect(imported_agreement.head_revision_id).not_to eq(amended_revision.id)
    expect(imported_agreement.head_revision.body).to eq(amended_revision.body)
    expect(imported.documents.find_by!(key: "standing-rule").schema_document.key).to eq("agreement")
    expect(imported.domain_commits.order(:created_at).pluck(:id)).not_to eq([ first_commit.id, second_commit.id ])
    expect(imported.head_domain_commit.state_hash).to eq(second_commit.state_hash)
    expect(imported.head_domain_commit.parent_domain_commit.state_hash).to eq(first_commit.state_hash)
    expect(imported.head_domain_commit.domain_commit_documents.find_by!(document_key: "standing-rule")).to have_attributes(
      revision_hash: a_string_matching(/\A\h{64}\z/)
    )
    expect(imported.documents.find_by!(key: "motion").schema_wrapper.edit_affordances.sole.title).to eq("Default")
  end

  it "rejects unsupported archive formats" do
    expect {
      DomainExports::Import.call(archive: { "format" => "nope", "version" => 1 })
    }.to raise_error(ArgumentError, "unsupported domain archive format")
  end

  def uuid_pattern
    /\b[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}\b/i
  end
end
