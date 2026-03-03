class Document < ApplicationRecord
  belongs_to :domain
  belongs_to :head_revision
end
