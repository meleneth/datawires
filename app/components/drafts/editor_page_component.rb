# frozen_string_literal: true

module Drafts
  class EditorPageComponent < ApplicationComponent
    attr_reader :page

    delegate :document, :draft, :cursor, to: :page

    def initialize(page:)
      @page = page
    end

    def title
      document.title.presence || document.key
    end

    def path_label
      cursor.path.to_s
    end

    def commit_path
      page.commit_path
    end

    def projected_rows?
      page.projected_rows.present?
    end

    def projected_rows_component
      Drafts::ProjectedRowsComponent.new(page: page)
    end
  end
end
