# frozen_string_literal: true

class DocumentEditorRow
  attr_reader :cells

  def initialize(cells:)
    @cells = cells
  end
end
