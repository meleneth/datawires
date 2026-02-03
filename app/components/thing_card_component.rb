class ThingCardComponent < ApplicationComponent
  renders_one :label

  def initialize(class_name: nil)
    @class_name = class_name
  end

  def card_classes
    cx(
      "block max-w-l p-6 rounded-lg shadow border transition",
      "bg-ls5-blue-1 border-ls5-blue-3 hover:bg-ls5-blue-2",
      @class_name
    )
  end
end
