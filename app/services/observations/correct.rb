# frozen_string_literal: true

module Observations
  class Correct
    def self.call(observation:, kind:, payload: {}, numeric_value: nil, actor: nil)
      raise ArgumentError, "correction kind is invalid" unless Observation::CORRECTION_KINDS.include?(kind)

      observation.source.observations.create!(
        domain: observation.domain,
        source_run: observation.source_run,
        configuration_revision: observation.configuration_revision,
        corrects_observation: observation,
        correction_kind: kind,
        observation_type: observation.observation_type,
        metric_key: observation.metric_key,
        unit: observation.unit,
        numeric_value: kind == "replace" ? numeric_value : nil,
        dimensions: observation.dimensions,
        payload:,
        observed_at: observation.observed_at,
        effective_at: Time.current,
        recorded_at: Time.current,
        provenance: observation.provenance.merge("correction_actor_id" => actor&.id, "corrects_observation_id" => observation.id).compact
      )
    end
  end
end
