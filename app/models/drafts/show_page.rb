# frozen_string_literal: true

module Drafts
  class ShowPage
    attr_reader :domain, :document, :draft, :cursor, :edit_affordance

    def initialize(domain:, document:, draft:, cursor:, edit_affordance:)
      @domain = domain
      @document = document
      @draft = draft
      @cursor = cursor
      @edit_affordance = edit_affordance
    end

    def projected_rows
      @projected_rows ||= edit_affordance&.projected_rows(cursor) || []
    end

    def diff_rows
      @diff_rows ||= Documents::Diff.rows(
        before: draft.based_on_revision&.body,
        after: draft.body
      )
    end

    def commit_path
      Rails.application.routes.url_helpers.new_draft_commit_path(
        draft,
        edit_affordance_id: edit_affordance&.id,
        path: cursor.path.to_s
      )
    end
  end
end
