# frozen_string_literal: true

class Membership < ApplicationRecord
  STATUSES = %w[active suspended ended].freeze

  belongs_to :body, inverse_of: :memberships
  belongs_to :actor, class_name: "User"
  belongs_to :recorded_by, class_name: "User", optional: true

  scope :effective_at, lambda { |time|
    where("effective_from <= ?", time)
      .where("effective_until IS NULL OR effective_until > ?", time)
      .where(status: "active")
  }

  validates :status, inclusion: { in: STATUSES }
  validates :effective_from, presence: true
  validate :effective_until_must_follow_start

  private

  def effective_until_must_follow_start
    return if effective_until.blank? || effective_from.blank? || effective_until > effective_from

    errors.add(:effective_until, "must be after effective from")
  end
end
