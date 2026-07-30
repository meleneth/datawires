# frozen_string_literal: true

module Meetings
  Projection = Data.define(
    :revision,
    :status,
    :opened_at,
    :adjourned_at,
    :attendance_actor_ids,
    :quorum,
    :recognition_requests,
    :floor_holder_id,
    :floor_reason,
    :floor_history,
    :scheduled_proposals,
    :pending_question_stack,
    :vote_state
  ) do
    def self.empty
      new(
        revision: 0,
        status: "scheduled",
        opened_at: nil,
        adjourned_at: nil,
        attendance_actor_ids: [],
        quorum: nil,
        recognition_requests: [],
        floor_holder_id: nil,
        floor_reason: nil,
        floor_history: [],
        scheduled_proposals: [],
        pending_question_stack: [],
        vote_state: nil
      )
    end

    def self.rebuild(records)
      records.reduce(empty) { |projection, record| projection.apply(record) }
    end

    def apply(record)
      attributes = to_h.merge(revision: record.sequence)
      effects = record.provenance["projection_effects"]
      if effects.is_a?(Array)
        attributes = ProceduralPolicies::ApplyEffects.call(state: attributes, effects:)
        return self.class.new(**attributes)
      end

      effects = ProceduralPolicies::LegacyEventEffects.call(record:)
      attributes = ProceduralPolicies::ApplyEffects.call(state: attributes, effects:)
      self.class.new(**attributes)
    end
  end
end
