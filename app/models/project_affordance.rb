# frozen_string_literal: true

class ProjectAffordance < ApplicationRecord
  belongs_to :domain, inverse_of: :project_affordance
  belongs_to :project_document,
             class_name: "Document",
             inverse_of: :project_affordance
  belongs_to :default_board, class_name: "Board", optional: true

  validates :domain_id, uniqueness: true
  validates :project_document_id, uniqueness: true
  validate :project_document_must_share_domain
  validate :project_document_must_use_project_schema
  validate :project_document_body_must_match_dsl
  validate :default_board_must_share_domain

  delegate :body, :head_revision, to: :project_document

  def title
    body["title"].presence || domain.name
  end

  def description
    body["description"].to_s
  end

  private

  def project_document_must_share_domain
    return if project_document.blank? || project_document.domain == domain

    errors.add(:project_document, "must belong to the project domain")
  end

  def project_document_must_use_project_schema
    return if project_document.blank?
    return if project_document.schema_document&.key == ProjectAffordances::Schema::KEY

    errors.add(:project_document, "must use the Datawires Project Affordance schema")
  end

  def project_document_body_must_match_dsl
    return if project_document.blank?

    ProjectAffordances::BodyValidator.new(project_document.body).errors.each do |message|
      errors.add(:project_document, message)
    end
  end

  def default_board_must_share_domain
    return if default_board.blank? || default_board.schema_wrapper.domain == domain

    errors.add(:default_board, "must belong to the project domain")
  end
end
