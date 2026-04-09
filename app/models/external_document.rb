# frozen_string_literal: true

class ExternalDocument < ApplicationRecord
  belongs_to :document, inverse_of: :external_document

  validates :canonical_uri, presence: true, uniqueness: true
  validates :source_kind, presence: true, inclusion: { in: %w[url file] }
end
