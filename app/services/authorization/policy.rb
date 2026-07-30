# frozen_string_literal: true

module Authorization
  class Policy
    def self.call(actor:, action:, resource:)
      return Decision.new(allowed: false, reason: "An authenticated actor is required.") unless actor.is_a?(ActorContext)

      allowed = actor.user.can?(action, **resource)
      Decision.new(
        allowed:,
        reason: allowed ? nil : "The actor is not allowed to #{action.to_s.humanize(capitalize: false)}."
      )
    end
  end
end
