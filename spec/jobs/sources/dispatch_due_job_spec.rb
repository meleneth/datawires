# frozen_string_literal: true

require "rails_helper"

RSpec.describe Sources::DispatchDueJob do
  include ActiveJob::TestHelper

  it "queues each due enabled source once and claims its due time" do
    due = create(:source, next_run_at: 1.minute.ago)
    create(:source, next_run_at: 1.hour.from_now)
    create(:source, enabled: false, status: "disabled", next_run_at: 1.minute.ago)

    expect {
      described_class.perform_now(now: Time.current)
    }.to have_enqueued_job(Sources::ExecuteJob).exactly(:once)

    expect(due.reload).to have_attributes(status: "queued")
    expect(due.next_run_at).to be_present
    expect(due.lease_token).to be_present
    expect(due.leased_until).to be > Time.current
  end

  it "does not duplicate an active claim and reclaims an expired one with the same schedule key" do
    due = create(:source, next_run_at: 1.minute.ago)
    now = Time.current
    described_class.perform_now(now:)

    expect { described_class.perform_now(now: now + 1.minute) }.not_to have_enqueued_job(Sources::ExecuteJob)

    due.update_columns(leased_until: now - 1.second)
    expect { described_class.perform_now(now: now + 1.minute) }.to have_enqueued_job(Sources::ExecuteJob).once
  end
end
