# frozen_string_literal: true

module Editors
  class DocumentObjectEditorComponent < ApplicationComponent
    attr_reader :draft, :editor_rows, :edit_affordance_id

    def initialize(draft:, editor_rows:, edit_affordance_id: nil)
      @draft = draft
      @editor_rows = editor_rows
      @edit_affordance_id = edit_affordance_id
    end
  end
end
