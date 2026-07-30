# frozen_string_literal: true

class RoleAssignment < ApplicationRecord
  SCOPE_TYPES = %w[Body Meeting].freeze

  belongs_to :actor, class_name: "User"
  belongs_to :scope, polymorphic: true
  belongs_to :recorded_by, class_name: "User", optional: true

  scope :effective_at, lambda { |time|
    where("effective_from <= ?", time)
      .where("effective_until IS NULL OR effective_until > ?", time)
  }

  validates :role, presence: true
  validates :scope_type, inclusion: { in: SCOPE_TYPES }
  validates :effective_from, presence: true
  validate :effective_until_must_follow_start
  validate :role_must_be_defined_by_applicable_policy

  private

  def effective_until_must_follow_start
    return if effective_until.blank? || effective_from.blank? || effective_until > effective_from

    errors.add(:effective_until, "must be after effective from")
  end

  def role_must_be_defined_by_applicable_policy
    return if role.blank? || scope.blank?
    return if applicable_roles.include?(role)

    errors.add(:role, "is not defined by the applicable procedural policy")
  end

  def applicable_roles
    if scope.is_a?(Meeting)
      scope.procedural_policy.projection.roles
    else
      policies = scope.procedural_policies.filter_map { |policy| policy.projection.roles }
      policies.flatten.uniq.presence || Authorization::BodyPolicy.default_capability_policy.roles
    end
  end
end
