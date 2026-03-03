class Draft < ApplicationRecord
  belongs_to :document
  belongs_to :based_on_revision
  belongs_to :created_by
end
