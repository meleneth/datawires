# frozen_string_literal: true

require "rails_helper"

RSpec.describe RobertsRules::ApplyMotion do
  it "creates an agreement, marks the motion applied, records an event, and commits the domain" do
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
        "relative_time" => -2,
        "new_agreement_key" => "speaking-rule",
        "proposed_text" => "Members may speak twice."
      }
    )
    previous_head = domain.head_domain_commit

    expect {
      described_class.call(motion_document: motion, actor: nil)
    }.to change(DomainCommit, :count).by(1)

    agreement = domain.documents.find_by!(key: "speaking-rule")
    event = domain.documents.find_by!(key: "motion-adopt-rule-applied-event")
    motion.reload

    expect(agreement.schema_document.key).to eq("agreement")
    expect(agreement.body).to include(
      "title" => "Adopt speaking rule",
      "status" => "active",
      "body" => "Members may speak twice.",
      "relative_time" => -2
    )
    expect(motion.body["result"]).to eq("applied: speaking-rule")
    expect(event.schema_document.key).to eq("proceeding-event")
    expect(event.body).to include(
      "event_type" => "rule",
      "motion_key" => "motion-adopt-rule",
      "agreement_key" => "speaking-rule"
    )
    expect(domain.reload.head_domain_commit.parent_domain_commit).to eq(previous_head)
    expect(domain.head_domain_commit.domain_commit_documents.pluck(:document_key)).to include(
      "motion-adopt-rule",
      "speaking-rule",
      "motion-adopt-rule-applied-event"
    )
  end

  it "amends an existing agreement from an adopted motion" do
    domain = seeded_domain
    agreement = roberts_document(
      domain: domain,
      schema_key: "agreement",
      key: "standing-rule",
      title: "Standing Rule",
      body: {
        "title" => "Standing Rule",
        "status" => "active",
        "body" => "Members may speak once."
      }
    )
    motion = roberts_document(
      domain: domain,
      schema_key: "motion",
      key: "motion-amend-rule",
      title: "Amend standing rule",
      body: {
        "title" => "Amend standing rule",
        "motion_type" => "amend",
        "status" => "adopted",
        "target_agreement_key" => "standing-rule",
        "proposed_text" => "Members may speak twice."
      }
    )

    expect {
      described_class.call(motion_document: motion, actor: nil)
    }.to change { agreement.reload.head_revision_id }

    expect(agreement.body).to include(
      "status" => "amended",
      "body" => "Members may speak twice."
    )
    expect(agreement.head_revision.parent_revision.body).to include(
      "status" => "active",
      "body" => "Members may speak once."
    )
    expect(motion.reload.body["result"]).to eq("applied: standing-rule")
  end

  it "extends an existing agreement by creating a linked agreement" do
    domain = seeded_domain
    roberts_document(
      domain: domain,
      schema_key: "agreement",
      key: "base-rule",
      title: "Base Rule",
      body: {
        "title" => "Base Rule",
        "status" => "active",
        "body" => "Base text."
      }
    )
    motion = roberts_document(
      domain: domain,
      schema_key: "motion",
      key: "motion-extend-rule",
      title: "Extend base rule",
      body: {
        "title" => "Extend base rule",
        "motion_type" => "extend",
        "status" => "adopted",
        "new_agreement_key" => "base-rule-extension",
        "target_agreement_key" => "base-rule",
        "proposed_text" => "Extension text."
      }
    )

    described_class.call(motion_document: motion, actor: nil)

    extension = domain.documents.find_by!(key: "base-rule-extension")
    expect(extension.body).to include(
      "status" => "active",
      "body" => "Extension text.",
      "extends_agreement_key" => "base-rule"
    )
    expect(motion.reload.body["result"]).to eq("applied: base-rule-extension")
  end

  it "closes an existing agreement from an adopted motion" do
    domain = seeded_domain
    agreement = roberts_document(
      domain: domain,
      schema_key: "agreement",
      key: "temporary-rule",
      title: "Temporary Rule",
      body: {
        "title" => "Temporary Rule",
        "status" => "active",
        "body" => "Temporary text."
      }
    )
    motion = roberts_document(
      domain: domain,
      schema_key: "motion",
      key: "motion-close-rule",
      title: "Close temporary rule",
      body: {
        "title" => "Close temporary rule",
        "motion_type" => "close",
        "status" => "adopted",
        "target_agreement_key" => "temporary-rule"
      }
    )

    described_class.call(motion_document: motion, actor: nil)

    expect(agreement.reload.body).to include(
      "status" => "closed",
      "body" => "Temporary text."
    )
    expect(motion.reload.body["result"]).to eq("applied: temporary-rule")
  end

  it "rejects motions that have not been adopted" do
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
      described_class.call(motion_document: motion, actor: nil)
    }.to raise_error(RobertsRules::ApplyMotion::Error, "only adopted motions can be applied")
    expect(DomainCommit.count).to eq(1)
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
