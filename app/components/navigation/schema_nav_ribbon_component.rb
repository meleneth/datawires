module Navigation
  # frozen_string_literal: true

  class SchemaNavRibbonComponent < ApplicationComponent
    def initialize(domain:, document:, draft:, path:, turbo_frame: "editor")
      @domain = domain
      @document = document
      @draft = draft
      @path = SchemaPath.normalize(path)
      @nav = SchemaNav.new(source_json)
      @turbo_frame = turbo_frame
    end

    attr_reader :domain, :document, :draft, :path, :turbo_frame

    def segments
      tokens = SchemaPath.new(path).tokens
      [ root_segment ] + token_segments(tokens)
    end

    def path_resolves?
      @nav.subschema_at(path).present?
    end

    private

    def root_segment
      SchemaRibbonSegment.new(
        label: "/",
        path: SchemaPath::ROOT,
        url: nav_url(SchemaPath::ROOT),
        current: path == SchemaPath::ROOT,
        menu_items: []
      )
    end

    def token_segments(tokens)
      tokens.each_with_index.map do |token, idx|
        parent_tokens = tokens[0...idx]
        parent_path = path_for_tokens(parent_tokens)
        segment_path = path_for_tokens(tokens[0..idx])

        sibling_keys = @nav.object_keys_at(parent_path).reject { |key| key == token }

        menu_items = sibling_keys.map do |key|
          item_path = path_for_tokens(parent_tokens + [ key ])

          SchemaRibbonMenuItem.new(
            label: key,
            path: item_path,
            url: nav_url(item_path),
            current: false
          )
        end

        SchemaRibbonSegment.new(
          label: token,
          path: segment_path,
          url: nav_url(segment_path),
          current: idx == tokens.length - 1,
          menu_items: menu_items
        )
      end
    end

    def path_for_tokens(tokens)
      ptr = SchemaPath.new(SchemaPath::ROOT)
      tokens.each do |token|
        ptr = ptr.child(token)
      end
      ptr.to_s
    end

    def nav_url(target_path)
      Rails.application.routes.url_helpers.draft_path(
        draft,
        path: SchemaPath.normalize(target_path)
      )
    end

    def tail_menu_items
      @nav.object_keys_at(path).map do |key|
        item_path = SchemaPath.new(path).child(key).to_s

        SchemaRibbonMenuItem.new(
          label: key,
          path: item_path,
          url: nav_url(item_path),
          current: false
        )
      end
    end

    def source_json
      draft&.body || {}
    end
  end
end
