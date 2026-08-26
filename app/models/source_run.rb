# frozen_string_literal: true

class SourceRun < ApplicationRecord
  STATUSES = %w[pending running succeeded failed retrying].freeze
  TRIGGERS = %w[manual scheduled retry].freeze

  belongs_to :source
  belongs_to :configuration_revision, class_name: "Revision"
  belongs_to :triggered_by, class_name: "User", optional: true
  has_many :observations, dependent: :restrict_with_exception

  validates :status, inclusion: { in: STATUSES }
  validates :trigger, inclusion: { in: TRIGGERS }
  validates :adapter, :adapter_version, :idempotency_key, presence: true
  validates :idempotency_key, uniqueness: { scope: :source_id }
end
