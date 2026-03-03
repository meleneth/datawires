# frozen_string_literal: true

class SchemaNavRibbonComponent < ViewComponent::Base
  def initialize(domain:, document:, draft:, ptr:, turbo_frame: "schema_workspace")
    @domain = domain
    @document = document
    @draft = draft
    @ptr = normalize_ptr(ptr)

    # Use draft body so navigation reflects uncommitted edits.
    @nav = JsonPtrNav.new(source_json)

    @turbo_frame = turbo_frame
  end

  attr_reader :domain, :document, :draft, :ptr, :turbo_frame

  def crumbs
    tokens = JsonPtr::Pointer.parse(ptr).tokens
    out = [{ label: "/", ptr: "" }]

    tokens.each_with_index do |tok, idx|
      out << { label: tok.unescaped, ptr: pointer_for(tokens.take(idx + 1)) }
    end

    out
  end

  def choices_for(ptr_at_level)
    @nav.object_keys_at(ptr_at_level)
  end

  def child_ptr(parent_ptr, child_key)
    @nav.child_ptr(parent_ptr, child_key)
  end

  def nav_url(target_ptr)
    # Adjust this helper to match your draft editor route.
    # Expected shape (recommended):
    # domain_document_draft_path(domain, document, draft, ptr: target_ptr)
    Rails.application.routes.url_helpers.domain_document_draft_path(
      domain,
      document,
      draft,
      ptr: target_ptr
    )
  end

  def ptr_resolves?
    @nav.value_at(ptr).present?
  end

  private

  def source_json
    draft&.body || {}
  end

  def normalize_ptr(raw)
    JsonPtr::Pointer.parse(raw.to_s).to_s
  rescue ArgumentError
    ""
  end

  def pointer_for(tokens)
    p = JsonPtr::Pointer.parse("")
    tokens.each { |t| p = p.child(t.unescaped) }
    p.to_s
  end
end
