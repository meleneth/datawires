class User < ApplicationRecord
  def can?(_capability, **_context)
    # TODO: integrate with real authorization system
    true
  end
end
