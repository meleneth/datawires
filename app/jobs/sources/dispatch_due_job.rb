# frozen_string_literal: true

module Sources
  class DispatchDueJob < ApplicationJob
    queue_as :default

    def perform(now: Time.current)
      Source.where(enabled: true).where(next_run_at: ..now).find_each do |source|
        bucket = source.next_run_at&.utc&.iso8601 || now.utc.iso8601
        source.update!(status: "queued", next_run_at: nil)
        Sources::ExecuteJob.perform_later(source.id, trigger: "scheduled", idempotency_key: "scheduled:#{bucket}")
      end
    end
  end
end
