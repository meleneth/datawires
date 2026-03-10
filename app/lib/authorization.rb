# app/lib/authorization.rb
module Authorization
  class NotAuthorized < StandardError; end

  def authorize!(capability, **context)
    return if Current.user&.can?(capability, **context)

    raise NotAuthorized, "#{capability} #{context.inspect}"
  end
end
