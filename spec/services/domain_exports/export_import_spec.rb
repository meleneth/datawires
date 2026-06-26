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

    clear_domain_graph!
    imported = DomainExports::Import.call(archive: archive)

    expect(imported).to have_attributes(
      id: domain.id,
      name: "Rules Archive",
      repository_mode: true
    )
    expect(imported.documents.find_by!(key: "standing-rule").head_revision_id).to eq(amended_revision.id)
    expect(imported.documents.find_by!(key: "standing-rule").schema_document.key).to eq("agreement")
    expect(imported.domain_commits.order(:created_at).pluck(:id)).to eq([ first_commit.id, second_commit.id ])
    expect(imported.head_domain_commit_id).to eq(second_commit.id)
    expect(imported.head_domain_commit.parent_domain_commit_id).to eq(first_commit.id)
    expect(imported.head_domain_commit.state_hash).to eq(second_commit.state_hash)
    expect(imported.head_domain_commit.domain_commit_documents.find_by!(document_key: "standing-rule")).to have_attributes(
      revision_id: amended_revision.id,
      revision_hash: a_string_matching(/\A\h{64}\z/)
    )
    expect(imported.documents.find_by!(key: "motion").schema_wrapper.edit_affordances.sole.title).to eq("Default")
  end

  it "rejects unsupported archive formats" do
    expect {
      DomainExports::Import.call(archive: { "format" => "nope", "version" => 1 })
    }.to raise_error(ArgumentError, "unsupported domain archive format")
  end

  def clear_domain_graph!
    Domain.update_all(head_domain_commit_id: nil)
    DomainCommitDocument.delete_all
    DomainCommit.delete_all
    EditAffordance.delete_all
    ViewAffordance.delete_all
    SchemaWrapper.delete_all
    DocumentIndexEntry.delete_all
    Draft.delete_all
    Document.update_all(head_revision_id: nil, schema_document_id: nil)
    Revision.delete_all
    Document.delete_all
    Domain.delete_all
  end
end
