# frozen_string_literal: true

module Drafts
  class ProjectedRowsComponent < ApplicationComponent
    attr_reader :page

    delegate :draft, :projected_rows, to: :page

    def initialize(page:)
      @page = page
    end

    def span_class_for(cell)
      return nil if cell.span.blank?

      "col-span-#{cell.span}"
    end

    def rendered_component_for(cell)
      case cell
      when EditAffordances::ProjectedField
        projected_field_component_for(cell)
      when EditAffordances::ProjectedCommit
        Drafts::ProjectedCommitComponent.new(page: page, commit: cell)
      else
        raise ArgumentError, "unsupported projected cell: #{cell.inspect}"
      end
    end

    private

    def projected_field_component_for(cell)
      if cell.widget == "array" || cell.cursor.array?
        Drafts::ProjectedArrayFieldComponent.new(page: page, field: cell)
      else
        Drafts::ProjectedFieldComponent.new(
          draft: draft,
          field: cell,
          edit_affordance_id: page.edit_affordance&.id
        )
      end
    end
  end
end
