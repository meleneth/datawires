# frozen_string_literal: true

class MetricDefinition < ApplicationRecord
  belongs_to :domain
  belongs_to :metric_document, class_name: "Document", inverse_of: :metric_definition

  validates :key, presence: true, uniqueness: { scope: :domain_id }
  validate :document_must_share_domain
  validate :document_must_use_metric_schema

  delegate :body, :head_revision, to: :metric_document

  private

  def document_must_share_domain
    return if metric_document.blank? || metric_document.domain == domain

    errors.add(:metric_document, "must belong to the metric domain")
  end

  def document_must_use_metric_schema
    return if metric_document.blank? || metric_document.schema_document&.key == Metrics::Schema::KEY

    errors.add(:metric_document, "must use the Datawires Metric schema")
  end
end
