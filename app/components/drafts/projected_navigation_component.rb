# frozen_string_literal: true

module Drafts
  class ProjectedNavigationComponent < ApplicationComponent
    attr_reader :page, :navigation

    delegate :draft, :edit_affordance, :cursor, to: :page

    def initialize(page:, navigation:)
      @page = page
      @navigation = navigation
    end

    def navigation_path
      params = {
        path: cursor.path.to_s,
        screen: navigation.target_screen_id
      }
      params[:edit_affordance_id] = edit_affordance.id if edit_affordance&.id

      draft_path(draft, params)
    end
  end
end
