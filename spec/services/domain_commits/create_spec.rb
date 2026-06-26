# frozen_string_literal: true

require "rails_helper"

RSpec.describe DomainCommits::Create do
  it "creates a tamper-evident domain commit from current document heads" do
    domain = create(:domain, repository_mode: true)
    document = create(:document, :with_head_revision, domain: domain, key: "agreement", head_body: { "name" => "Standing rule" })

    commit = described_class.call(domain: domain, message: "Initial state", actor: nil)

    expect(commit).to be_persisted
    expect(commit.parent_domain_commit).to be_nil
    expect(commit.state_hash).to match(/\A\h{64}\z/)
    expect(domain.reload.head_domain_commit).to eq(commit)
    expect(commit.domain_commit_documents.sole).to have_attributes(
      document: document,
      revision: document.head_revision,
      document_key: "agreement"
    )
    expect(commit.domain_commit_documents.sole.revision_hash).to match(/\A\h{64}\z/)
  end

  it "chains commits through the domain head and changes hash when document state changes" do
    domain = create(:domain, repository_mode: true)
    document = create(:document, :with_head_revision, domain: domain, key: "agreement", head_body: { "name" => "Original" })
    first = described_class.call(domain: domain, message: "Original", actor: nil)

    revision = create(:revision, document: document, parent_revision: document.head_revision, body: { "name" => "Amended" })
    document.update!(head_revision: revision)

    second = described_class.call(domain: domain, message: "Amended", actor: nil)

    expect(second.parent_domain_commit).to eq(first)
    expect(second.state_hash).not_to eq(first.state_hash)
    expect(domain.reload.head_domain_commit).to eq(second)
    expect(second.domain_commit_documents.sole.revision).to eq(revision)
  end
end
