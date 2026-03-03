class Revision < ApplicationRecord
  belongs_to :document
  belongs_to :parent_revision
  belongs_to :created_by
end
