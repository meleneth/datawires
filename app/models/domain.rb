class Domain < ApplicationRecord
  has_many :documents, dependent: :restrict_with_exception

  def open_drafts
    Draft.joins(:document)
        .where(documents: { domain_id: id })
        .includes(:document)
  end
end
