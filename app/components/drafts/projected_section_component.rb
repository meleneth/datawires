# frozen_string_literal: true

module Drafts
  class ProjectedSectionComponent < ApplicationComponent
    attr_reader :section

    delegate :cursor, to: :section

    def initialize(section:)
      @section = section
    end

    def title
      cursor.name.to_s.humanize
    end
  end
end
