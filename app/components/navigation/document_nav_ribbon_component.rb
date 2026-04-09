module Navigation
  # frozen_string_literal: true

  class Navigation::DocumentNavRibbonComponent < ApplicationComponent
    def initialize(document:, draft:, path:, turbo_frame: "editor")
      @document = document
      @draft = draft
      @path = path.is_a?(Documents::Path) ? path : Documents::Path.new(path)
      @projection = Documents::Projection.new(source: draft, path: @path)
      @turbo_frame = turbo_frame
    end

    attr_reader :document, :draft, :path, :projection, :turbo_frame

    def segments
      tokens = path.tokens
      [ root_segment ] + token_segments(tokens)
    end

    def path_resolves?
      projection.schema_node.present?
    end

    def tail_menu_items
      schema_child_keys_at(path).map do |key|
        item_path = path.child(key)

        Schemas::RibbonMenuItem.new(
          label: key,
          path: item_path.to_s,
          url: nav_url(item_path),
          current: false
        )
      end
    end

    private

    def root_segment
      Schemas::RibbonSegment.new(
        label: "/",
        path: Documents::Path::ROOT,
        url: nav_url(Documents::Path::ROOT),
        current: path.root?,
        menu_items: []
      )
    end

    def token_segments(tokens)
      tokens.each_with_index.map do |token, idx|
        parent_tokens = tokens[0...idx]
        parent_path = path_for_tokens(parent_tokens)
        segment_path = path_for_tokens(tokens[0..idx])

        sibling_keys = schema_child_keys_at(parent_path).reject { |key| key == token }

        menu_items = sibling_keys.map do |key|
          item_path = path_for_tokens(parent_tokens + [ key ])

          Schemas::RibbonMenuItem.new(
            label: key,
            path: item_path.to_s,
            url: nav_url(item_path),
            current: false
          )
        end

        Schemas::RibbonSegment.new(
          label: token,
          path: segment_path.to_s,
          url: nav_url(segment_path),
          current: idx == tokens.length - 1,
          menu_items: menu_items
        )
      end
    end

    def path_for_tokens(tokens)
      tokens.reduce(Documents::Path.new(Documents::Path::ROOT)) do |current_path, token|
        current_path.child(token)
      end
    end

    def nav_url(target_path)
      Rails.application.routes.url_helpers.draft_path(
        draft,
        path: Documents::Path.new(target_path).to_s
      )
    end

    def schema_child_keys_at(target_path)
      projection_at(target_path).schema_child_keys
    end

    def projection_at(target_path)
      Documents::Projection.new(source: draft, path: target_path)
    end
  end
end
