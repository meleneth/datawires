# frozen_string_literal: true

module Sources
  class ExecuteJob < ApplicationJob
    queue_as :default
    retry_on Sources::Adapters::HttpJson::ResponseError, wait: :polynomially_longer, attempts: 5
    retry_on Net::OpenTimeout, Net::ReadTimeout, wait: :polynomially_longer, attempts: 5

    def perform(source_id, trigger: "scheduled", actor_id: nil, idempotency_key: nil, lease_token: nil)
      source = Source.find(source_id)
      actor = User.find_by(id: actor_id)
      lease_token = valid_or_new_lease(source, lease_token)
      raise Sources::LeaseUnavailable, "source execution is already leased" unless lease_token

      Sources::Execute.call(source:, trigger:, actor:, idempotency_key: idempotency_key || SecureRandom.uuid)
    rescue Sources::Adapters::HttpJson::ResponseError, Net::OpenTimeout, Net::ReadTimeout
      run = source&.source_runs&.find_by(idempotency_key:)
      run&.update!(status: "retrying", attempt: run.attempt + 1) if executions < 5
      raise
    ensure
      source&.release_execution_lease(lease_token) if lease_token
    end


    private

    def valid_or_new_lease(source, token)
      return token if token.present? && source.lease_token == token && source.leased_until&.future?

      source.acquire_execution_lease
    end
  end
end
