# frozen_string_literal: true

module Drafts
  class ProjectedCommitComponent < ApplicationComponent
    attr_reader :page, :commit

    delegate :draft, :edit_affordance, :cursor, to: :page

    def initialize(page:, commit:)
      @page = page
      @commit = commit
    end

    def commit_path
      new_draft_commit_path(
        draft,
        path: cursor.path.to_s,
        edit_affordance_id: edit_affordance&.id
      )
    end
  end
end
