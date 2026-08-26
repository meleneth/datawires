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

    expect(due.reload).to have_attributes(status: "queued", next_run_at: nil)
  end
end
