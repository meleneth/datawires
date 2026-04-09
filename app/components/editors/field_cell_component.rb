# frozen_string_literal: true

module Editors
  class FieldCellComponent < ApplicationComponent
    attr_reader :cell, :draft, :edit_affordance_id

    def initialize(cell:, draft:, edit_affordance_id: nil)
      @cell = cell
      @draft = draft
      @edit_affordance_id = edit_affordance_id
    end

    def row
      cell.projection_row
    end

    def open_path
      helpers.draft_path(
        draft,
        path: row.path.to_s,
        edit_affordance_id: edit_affordance_id
      )
    end
  end
end
