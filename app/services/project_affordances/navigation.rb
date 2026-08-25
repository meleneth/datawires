# frozen_string_literal: true

module ProjectAffordances
  class Navigation
    include Rails.application.routes.url_helpers

    def self.for(project_affordance)
      new(project_affordance).groups
    end

    def initialize(project_affordance)
      @project_affordance = project_affordance
      @domain = project_affordance.domain
    end

    def groups
      Array(project_affordance.body["groups"]).filter_map do |group|
        next unless group.is_a?(Hash)

        links = Array(group["links"]).filter_map { |link| resolve(link) }
        { "title" => group["title"].presence || "Project", "links" => links }
      end
    end

    private

    attr_reader :project_affordance, :domain

    def resolve(link)
      return unless link.is_a?(Hash)

      href = href_for(link)
      return if href.blank?

      { "title" => link["title"].presence || href, "description" => link["description"].to_s, "href" => href }
    end

    def href_for(link)
      case link["kind"]
      when "domain" then domain_path(domain)
      when "repository_history" then domain_domain_commits_path(domain)
      when "schema" then schema_href(link)
      when "document" then document_href(link)
      when "view" then view_href(link)
      when "board" then board_href(link)
      end
    end

    def schema_href(link)
      document = document_for(link["schema_key"])
      schema_path(document.schema_wrapper) if document&.schema_wrapper
    end

    def document_href(link)
      document = document_for(link["document_key"])
      document_path(document) if document
    end

    def view_href(link)
      document = document_for(link["document_key"])
      schema = document_for(link["schema_key"]) || document&.schema_document
      return unless document && schema&.schema_wrapper

      views = schema.schema_wrapper.view_affordances
      view = link["view_title"].present? ? views.find_by(title: link["view_title"]) : views.order(:title).first
      document_view_affordance_path(document, view) if view
    end

    def board_href(link)
      board = Board.joins(schema_wrapper: :document)
        .where(documents: { domain_id: domain.id })
        .find_by(title: link["board_title"])
      board_path(board) if board
    end

    def document_for(key)
      domain.documents.find_by(key: key.to_s.strip.presence)
    end
  end
end
