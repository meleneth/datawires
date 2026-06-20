class ApplicationComponent < ViewComponent::Base
  include Rails.application.routes.url_helpers

  private

  def cx(*parts)
    parts.flatten.compact.join(" ")
  end
end
