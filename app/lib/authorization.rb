# app/lib/authorization.rb
module Authorization
  class NotAuthorized < StandardError; end

  def authorize!(capability, **context)
    decision = Authorization::Policy.call(
      actor: current_actor,
      action: capability,
      resource: context
    )
    return decision if decision.allowed?

    raise NotAuthorized, decision.reason
  end
end
