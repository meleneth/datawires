# frozen_string_literal: true

class DocumentIndexEntry < ApplicationRecord
  belongs_to :document
  belongs_to :revision
  belongs_to :schema_document,
             class_name: "Document"

  validates :index_type, presence: true
end
