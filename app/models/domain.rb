class Domain < ApplicationRecord
  has_many :documents, dependent: :restrict_with_exception
end
