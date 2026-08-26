# frozen_string_literal: true

class Observation < ApplicationRecord
  CORRECTION_KINDS = %w[replace retract].freeze

  belongs_to :domain
  belongs_to :source
  belongs_to :source_run
  belongs_to :configuration_revision, class_name: "Revision"
  belongs_to :corrects_observation, class_name: "Observation", optional: true
  has_many :corrections, class_name: "Observation", foreign_key: :corrects_observation_id, dependent: :restrict_with_exception

  validates :observation_type, :observed_at, :effective_at, :recorded_at, presence: true
  validates :correction_kind, inclusion: { in: CORRECTION_KINDS }, allow_nil: true
  validate :lineage_must_match

  before_update :prevent_mutation
  before_destroy :prevent_mutation

  private

  def lineage_must_match
    return if source.blank? || source_run.blank? || configuration_revision.blank?

    errors.add(:domain, "must match the source domain") unless domain == source.domain
    errors.add(:source_run, "must belong to the source") unless source_run.source == source
    return if source_run.configuration_revision == configuration_revision

    errors.add(:configuration_revision, "must match the source run")
  end

  def prevent_mutation
    raise ActiveRecord::ReadOnlyRecord, "Observations are append-only"
  end
end
