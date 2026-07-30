# frozen_string_literal: true

module Authorization
  class BodyPolicy
    ROLE_CAPABILITIES = {
      submit_proposal: %w[member chair secretary temporary_chair],
      create_meeting: %w[chair secretary],
      open_meeting: %w[chair temporary_chair],
      record_minutes: %w[secretary],
      vote: %w[member chair secretary temporary_chair],
      chair_action: %w[chair temporary_chair],
      administer_board: %w[chair secretary]
    }.freeze

    def self.call(actor:, action:, body:, meeting: nil, at: Time.current)
      return Decision.new(allowed: false, reason: "An authenticated actor is required.") unless actor.is_a?(ActorContext)
      return Decision.new(allowed: false, reason: "Unknown Body capability.") unless ROLE_CAPABILITIES.key?(action.to_sym)

      roles = effective_roles(actor.user, body, meeting, at)
      allowed = (roles & ROLE_CAPABILITIES.fetch(action.to_sym)).any?
      Decision.new(
        allowed:,
        reason: allowed ? nil : "The actor lacks an effective Body role for #{action.to_s.humanize(capitalize: false)}."
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
