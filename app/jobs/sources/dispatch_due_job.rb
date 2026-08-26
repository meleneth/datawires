# frozen_string_literal: true

module Sources
  class DispatchDueJob < ApplicationJob
    queue_as :default

    def perform(now: Time.current)
      Source.where(enabled: true).where(next_run_at: ..now).find_each do |source|
        source.with_lock do
          next unless source.enabled? && source.next_run_at&.<=(now)
          next if source.leased_until&.>(now)

          bucket = source.next_run_at.utc.iso8601
          token = SecureRandom.uuid
          source.update!(status: "queued", lease_token: token, leased_until: now + 5.minutes)
          Sources::ExecuteJob.perform_later(source.id, trigger: "scheduled", idempotency_key: "scheduled:#{bucket}",
            lease_token: token)
        end
      end
    end
  end
end
