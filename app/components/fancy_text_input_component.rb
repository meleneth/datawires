class FancyTextInputComponent < ViewComponent::Base
  def initialize(id:, label:, form:, name:, button_text: "»")
    @id = id

    @name = name
    @label = label
    @form = form
    @button_text = button_text
  end
end
