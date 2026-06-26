# frozen_string_literal: true

class DomainHomeLinks
  include Rails.application.routes.url_helpers

  DOCUMENT_KEY = "domain-home"

  def self.for(domain)
    new(domain).groups
  end

  def initialize(domain)
    @domain = domain
  end

  def groups
    Array(home_document&.body&.fetch("groups", nil)).filter_map do |group|
      next unless group.is_a?(Hash)

      links = Array(group["links"]).filter_map { |link| resolve_link(link) }
      next if links.empty?

      {
        "title" => group["title"].presence || "Links",
        "links" => links
      }
    end
  end

  private

  attr_reader :domain

  def home_document
    @home_document ||= domain.documents.includes(:head_revision).find_by(key: DOCUMENT_KEY)
  end

  def resolve_link(link)
    return nil unless link.is_a?(Hash)

    href = href_for(link)
    return nil if href.blank?

    {
      "title" => link["title"].presence || href,
      "description" => link["description"].to_s,
      "href" => href
    }
  end

  def href_for(link)
    case link["kind"]
    when "domain"
      domain_path(domain)
    when "repository_history"
      domain_domain_commits_path(domain)
    when "schema"
      schema = document_for_key(link["schema_key"])
      schema&.schema_wrapper ? schema_path(schema.schema_wrapper) : nil
    when "document"
      document = document_for_key(link["document_key"])
      document ? document_path(document) : nil
    when "view"
      view_href_for(link)
    end
  end

  def view_href_for(link)
    document = document_for_key(link["document_key"])
    schema = document_for_key(link["schema_key"]) || document&.schema_document
    view_affordance = view_affordance_for(schema, link["view_title"])
    return nil unless document && view_affordance

    document_view_affordance_path(document, view_affordance)
  end

  def view_affordance_for(schema, title)
    return nil unless schema&.schema_wrapper

    scope = schema.schema_wrapper.view_affordances
    title.present? ? scope.find_by(title: title) : scope.order(:title).first
  end

  def document_for_key(key)
    normalized = key.to_s.strip
    return nil if normalized.blank?

    domain.documents.find_by(key: normalized)
  end
end
