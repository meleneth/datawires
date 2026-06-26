# frozen_string_literal: true

require "rails_helper"
require Rails.root.join("db/seeds/roberts_rules_demo")

RSpec.describe Seeds::RobertsRulesDemo do
  it "seeds a deterministic repository-mode Robert's Rules demo domain" do
    expect {
      described_class.seed!
    }.to change(DomainCommit, :count).by(2)

    domain = Domain.find(described_class::DOMAIN_ID)
    expect(domain.name).to eq("Robert's Rules Demo")
    expect(domain).to be_repository_mode
    expect(domain.documents.where(key: %w[agreement motion proceeding-event meeting-state domain-home-page]).count).to eq(5)

    home = domain.documents.find_by!(key: "domain-home")
    expect(home.id).to eq(described_class::DOCUMENT_IDS.fetch("domain-home"))
    expect(home.schema_document.key).to eq("domain-home-page")
    expect(home.body.fetch("groups").flat_map { |group| group.fetch("links") }.pluck("title")).to include(
      "Agreements",
      "Motions",
      "Proceeding Events"
    )

    agreement = domain.documents.find_by!(key: "speaking-limits")
    motion = domain.documents.find_by!(key: "motion-amend-speaking-limits")
    event = domain.documents.find_by!(key: "speaking-limits-amended")
    meeting_state = domain.documents.find_by!(key: "current-meeting")

    expect(agreement.id).to eq(described_class::DOCUMENT_IDS.fetch("speaking-limits"))
    expect(agreement.schema_document.key).to eq("agreement")
    expect(agreement.body).to include(
      "status" => "amended",
      "relative_time" => 30
    )
    expect(motion.schema_document.key).to eq("motion")
    expect(motion.body).to include(
      "motion_type" => "amend",
      "status" => "adopted",
      "target_agreement_key" => "speaking-limits",
      "result" => "applied: speaking-limits"
    )
    expect(event.schema_document.key).to eq("proceeding-event")
    expect(event.body).to include(
      "motion_key" => "motion-amend-speaking-limits",
      "agreement_key" => "speaking-limits"
    )
    expect(meeting_state.body).to include(
      "phase" => "adjourned",
      "current_agreement_key" => "speaking-limits"
    )

    proceeding_schema = domain.documents.find_by!(key: "proceeding-event")
    proceeding_view = proceeding_schema.schema_wrapper.view_affordances.sole
    timeline_events = ViewAffordances::Projection.build(document: event, view_affordance: proceeding_view).data.fetch("events").map { |entry| entry.fetch("title") }
    expect(timeline_events).to include(
      "Meeting opens",
      "Speaking limits adopted",
      "Meeting adjourned"
    )

    expect(domain.head_domain_commit.message).to eq(described_class::MESSAGE)
    expect(domain.head_domain_commit.parent_domain_commit.message).to eq("Seed Robert's Rules of Order cluster")
    expect(domain.head_domain_commit.domain_commit_documents.count).to eq(24)
  end

  it "is idempotent" do
    described_class.seed!

    expect {
      described_class.seed!
    }.not_to change { [ Domain.count, Document.count, Revision.count, DomainCommit.count ] }
  end
end
