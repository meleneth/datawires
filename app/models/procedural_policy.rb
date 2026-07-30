# frozen_string_literal: true

class ProceduralPolicy < ApplicationRecord
  belongs_to :policy_document, class_name: "Document"
  belongs_to :body
  has_many :meetings, dependent: :restrict_with_exception

  validates :name, presence: true, uniqueness: { scope: :body_id }
  validate :document_must_be_valid_policy

  def projection
    ProceduralPolicies::Projection.build(policy_document.body)
  end

  private

  def document_must_be_valid_policy
    return if policy_document.blank?

    errors.add(:policy_document, "must use the Procedural Policy schema") unless policy_document.schema_document&.key == ProceduralPolicies::Schema::KEY
    errors.add(:policy_document, "must share the Body domain") unless policy_document.domain == body&.domain
    ProceduralPolicies::BodyValidator.new(policy_document.body).errors.each do |error|
      errors.add(:policy_document, error)
    end
  end
end
