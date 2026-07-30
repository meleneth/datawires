# frozen_string_literal: true

module ProceduralPolicies
  module Defaults
    MEETING_LIFECYCLE_PATH = Rails.root.join(
      "config/procedural_policies/datawires_meeting_lifecycle_v1.json"
    ).freeze

    module_function

    def meeting_lifecycle
      @meeting_lifecycle ||= UuidTools.deep_freeze(
        JSON.parse(MEETING_LIFECYCLE_PATH.read)
      )
    end
  end
end
