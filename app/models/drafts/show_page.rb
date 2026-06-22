# frozen_string_literal: true

module Drafts
  class ShowPage
    attr_reader :domain, :document, :draft, :cursor, :screen_id, :edit_affordance

    def initialize(domain:, document:, draft:, cursor:, screen_id: nil, edit_affordance:)
      @domain = domain
      @document = document
      @draft = draft
      @cursor = cursor
      @screen_id = screen_id
      @edit_affordance = edit_affordance
    end

    def projection
      @projection ||= Documents::Projection.new(
        source: draft,
        path: cursor.path,
        edit_affordance: edit_affordance&.body
      )
    end

    def editor_dispatcher
      @editor_dispatcher ||= Editors::Dispatcher.new(projection: projection)
    end

    def projected_rows
      return [] unless projection.location_kind == :object

      @projected_rows ||= edit_affordance_projection&.rows || []
    end

    def edit_affordance_projection
      @edit_affordance_projection ||= edit_affordance&.projection(cursor, screen_id: screen_id)
    end

    def diff_rows
      @diff_rows ||= Documents::Diff.rows(
        before: draft.based_on_revision&.body,
        after: draft.body
      )
    end

    def editor_stream_name
      [ draft, cursor.path.to_s, :editor ]
    end

    def editor_dom_id
      draft.editor_dom_id_for(cursor.path)
    end

    def commit_path
      Rails.application.routes.url_helpers.new_draft_commit_path(
        draft,
        edit_affordance_id: edit_affordance&.id,
        path: cursor.path.to_s,
        screen: edit_affordance_projection&.start_screen_id
      )
    end

    def immediate_commit_path
      Rails.application.routes.url_helpers.draft_commit_path(
        draft,
        edit_affordance_id: edit_affordance&.id,
        path: cursor.path.to_s,
        screen: edit_affordance_projection&.start_screen_id
      )
    end

    def commit_mode
      edit_affordance_projection&.start_screen&.commit_mode.presence || "review_screen"
    end

    def editor_width
      edit_affordance_projection&.start_screen&.width.presence ||
        edit_affordance_projection&.defaults&.width.presence ||
        "large"
    end
  end
end
