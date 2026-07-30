# frozen_string_literal: true

ActorContext = Data.define(:user, :claims) do
  def initialize(user:, claims:)
    raise ArgumentError, "user must be a User" unless user.is_a?(User)
    raise ArgumentError, "claims must be Identity::Claims" unless claims.is_a?(Identity::Claims)

    super
    freeze
  end
end
