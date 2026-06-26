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
        screen: page.edit_affordance_projection&.start_screen_id,
        edit_affordance_id: edit_affordance&.id
      )
    end

    def immediate_commit_path
      draft_commit_path(
        draft,
        path: cursor.path.to_s,
        screen: page.edit_affordance_projection&.start_screen_id,
        edit_affordance_id: edit_affordance&.id
      )
    end

    def immediate_commit?
      commit.commit_mode == "immediate"
    end

    def inline_message?
      commit.message_mode.in?(%w[inline_optional inline_required])
    end

    def message_required?
      commit.message_mode == "inline_required"
    end
  end
end
