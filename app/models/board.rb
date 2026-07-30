# frozen_string_literal: true

require "forwardable"

class Board < ApplicationRecord
  extend Forwardable

  belongs_to :schema_wrapper, inverse_of: :boards
  belongs_to :board_document,
             class_name: "Document",
             inverse_of: :board

  def_delegators :board_document, :head_revision

  scope :for_schema, ->(schema_wrapper) { where(schema_wrapper:) }
  scope :publicly_available, -> { where(public: true) }

  validates :title, presence: true, uniqueness: { scope: :schema_wrapper_id }
  validate :board_document_must_be_separate
  validate :board_document_must_share_domain
  validate :board_document_must_use_board_schema
  validate :board_document_body_must_match_dsl

  def body
    head_revision&.body || {}
  end

  def projection
    Boards::Projection.build(self)
  end

  private

  def board_document_must_be_separate
    return if board_document_id.blank? || schema_wrapper&.document_id.blank?
    return unless board_document_id == schema_wrapper.document_id

    errors.add(:board_document, "must be a separate document")
  end

  def board_document_body_must_match_dsl
    return if board_document.blank?

    validator = Boards::BodyValidator.new(head_revision&.body)
    validator.errors.each { |message| errors.add(:board_document, message) }
  end

  def board_document_must_share_domain
    return if board_document.blank? || schema_wrapper.blank?
    return if board_document.domain == schema_wrapper.domain

    errors.add(:board_document, "must belong to the schema wrapper domain")
  end

  def board_document_must_use_board_schema
    return if board_document.blank?
    return if board_document.schema_document&.key == Boards::Schema::KEY

    errors.add(:board_document, "must use the Datawires Board schema")
  end
end
