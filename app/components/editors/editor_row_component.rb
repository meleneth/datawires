# frozen_string_literal: true

module Editors
  class EditorRowComponent < ApplicationComponent
    attr_reader :row, :draft, :edit_affordance_id, :current_path

    def initialize(row:, draft:, edit_affordance_id: nil, current_path: nil)
      @row = row
      @draft = draft
      @edit_affordance_id = edit_affordance_id
      @current_path = current_path
    end
  end
end
