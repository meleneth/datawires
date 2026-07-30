# frozen_string_literal: true

module Authorization
  Decision = Data.define(:allowed, :reason) do
    def allowed?
      allowed
    end
  end
end
