# frozen_string_literal: true

module Authorization
  class BodyPolicy
    def self.call(actor:, action:, body:, meeting: nil, at: Time.current, capability_policy: default_capability_policy)
      return Decision.new(allowed: false, reason: "An authenticated actor is required.") unless actor.is_a?(ActorContext)
      allowed_roles = capability_policy.roles_for(action)
      return Decision.new(allowed: false, reason: "Unknown Body capability.") unless allowed_roles

      roles = effective_roles(actor.user, body, meeting, at)
      allowed = (roles & allowed_roles).any?
      Decision.new(
        allowed:,
        reason: allowed ? nil : "The actor lacks an effective Body role for #{action.to_s.humanize(capitalize: false)}."
      )
    end

    def self.default_capability_policy
      @default_capability_policy ||= ProceduralPolicies::Projection.build(
        ProceduralPolicies::Defaults.meeting_lifecycle
      )
    end

    def self.effective_roles(user, body, meeting, at)
      roles = body.role_assignments_at(at).where(actor: user).pluck(:role)
      roles.concat(meeting.role_assignments.effective_at(at).where(actor: user).pluck(:role)) if meeting
      roles << "member" if body.memberships_at(at).exists?(actor: user)
      roles.uniq
    end
    private_class_method :effective_roles
  end
end
