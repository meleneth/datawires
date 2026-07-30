# frozen_string_literal: true

class SchemaWrapper < ApplicationRecord
  belongs_to :document, inverse_of: :schema_wrapper

  has_many :edit_affordances,
           inverse_of: :schema_wrapper,
           dependent: :destroy

  has_many :view_affordances,
           inverse_of: :schema_wrapper,
           dependent: :destroy

  has_many :boards,
           inverse_of: :schema_wrapper,
           dependent: :destroy

  belongs_to :default_board,
             class_name: "Board",
             optional: true

  delegate :key, :title, :domain, :head_revision, :body, to: :document

  validate :default_board_must_belong_to_wrapper

  scope :publicly_available, -> { where(public: true) }

  validate :document_must_be_schema

  def conforming_documents
    document.instance_documents.with_head.order(:title, :key)
  end

  private

  def default_board_must_belong_to_wrapper
    return if default_board.blank? || default_board.schema_wrapper == self

    errors.add(:default_board, "must belong to this schema wrapper")
  end

  def document_must_be_schema
    return if document&.supported_schema?

    errors.add(:document, "must be a supported schema document")
  end
end
