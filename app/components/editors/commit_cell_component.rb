# frozen_string_literal: true

module Editors
  class CommitCellComponent < ApplicationComponent
    attr_reader :cell, :draft, :edit_affordance_id

    def initialize(cell:, draft:, edit_affordance_id: nil)
      @cell = cell
      @draft = draft
      @edit_affordance_id = edit_affordance_id
    end

    def show_message?
      cell.message_mode != "hidden"
    end

    def message_required?
      cell.message_mode == "inline_required"
    end
  end
end
