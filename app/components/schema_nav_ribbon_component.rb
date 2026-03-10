# frozen_string_literal: true

class SchemaNavRibbonComponent < ApplicationComponent
  def initialize(domain:, document:, draft:, path:, turbo_frame: "schema_workspace")
    @domain = domain
    @document = document
    @draft = draft
    @path = SchemaPath.normalize(path)
    @nav = SchemaNav.new(source_json)
    @turbo_frame = turbo_frame
  end

  attr_reader :domain, :document, :draft, :path, :turbo_frame

  def crumbs
    current = SchemaPath.new(path)

    out = [{ label: "/", path: SchemaPath::ROOT }]

    running = SchemaPath.new(SchemaPath::ROOT)
    current.tokens.each do |token|
      running = running.child(token)
      out << { label: token, path: running.to_s }
    end

    out
  end

  def choices_for(path_at_level)
    @nav.object_keys_at(path_at_level)
  end

  def child_path(parent_path, child_key)
    @nav.child_path(parent_path, child_key)
  end

  def nav_url(target_path)
    Rails.application.routes.url_helpers.draft_path(
      draft,
      path: SchemaPath.normalize(target_path)
    )
  end

  def path_resolves?
    @nav.subschema_at(path).present?
  end

  private

  def source_json
    draft&.body || {}
  end
end
