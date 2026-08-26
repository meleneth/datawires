# frozen_string_literal: true

module Sources
  class ExecuteJob < ApplicationJob
    queue_as :default
    retry_on Sources::Adapters::HttpJson::ResponseError, wait: :polynomially_longer, attempts: 5
    retry_on Net::OpenTimeout, Net::ReadTimeout, wait: :polynomially_longer, attempts: 5

    def perform(source_id, trigger: "scheduled", actor_id: nil, idempotency_key: nil)
      source = Source.find(source_id)
      actor = User.find_by(id: actor_id)
      Sources::Execute.call(source:, trigger:, actor:, idempotency_key: idempotency_key || SecureRandom.uuid)
    end
  end
end
