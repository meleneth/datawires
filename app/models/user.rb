class User < ApplicationRecord
  has_many :owned_domains,
           class_name: "Domain",
           foreign_key: :owner_id,
           inverse_of: :owner,
           dependent: :nullify

  validates :external_id, uniqueness: true, allow_blank: true

  def visible_domains
    Domain.visible_to(self)
  end

  def can?(_capability, **_context)
    # TODO: integrate with real authorization system
    true
  end
end
