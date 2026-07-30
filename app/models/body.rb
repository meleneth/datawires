# frozen_string_literal: true

class Body < ApplicationRecord
  belongs_to :body_document,
             class_name: "Document",
             inverse_of: :parliamentary_body

  has_many :memberships, dependent: :destroy, inverse_of: :body
  has_many :role_assignments, as: :scope, dependent: :destroy
  has_many :meetings, dependent: :destroy
  has_many :proposals, dependent: :destroy
  has_many :procedural_policies, dependent: :destroy

  delegate :domain, :key, :title, :body, to: :body_document

  validate :document_must_use_body_schema

  def memberships_at(time)
    memberships.effective_at(time)
  end

  def role_assignments_at(time)
    role_assignments.effective_at(time)
  end

  private

  def document_must_use_body_schema
    return if body_document&.schema_document&.key == Bodies::Schema::KEY

    errors.add(:body_document, "must use the Body schema")
  end
end
