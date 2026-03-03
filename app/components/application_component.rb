class ApplicationComponent < ViewComponent::Base
  private

  def cx(*parts)
    parts.flatten.compact.join(" ")
  end
end
