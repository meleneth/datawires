# frozen_string_literal: true

module Editors
  class EditorRowComponent < ApplicationComponent
    attr_reader :row, :draft, :edit_affordance_id

    def initialize(row:, draft:, edit_affordance_id: nil)
      @row = row
      @draft = draft
      @edit_affordance_id = edit_affordance_id
    end
  end
end
