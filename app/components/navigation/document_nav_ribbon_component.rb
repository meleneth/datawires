# frozen_string_literal: true

module Navigation
  class DocumentNavRibbonComponent < ApplicationComponent
    def initialize(document:, draft:, path:, turbo_frame:)
      @document = document
      @draft = draft
      @path = path.is_a?(Documents::Path) ? path : Documents::Path.new(path)
      @turbo_frame = turbo_frame
    end

    def segments
      paths = [ Documents::Path.root ]
      current = Documents::Path.root

      @path.tokens.each do |token|
        current = current.child(token)
        paths << current
      end

      paths
    end

    def child_links
      JsonPtr::Nav.new(@draft.body).object_keys_at(@path.to_s).map do |key|
        child_path = @path.child(key)
        [ key, draft_path(@draft, path: child_path.to_s) ]
      end
    end

    def segment_label(path)
      path.root? ? @document.title.presence || @document.key : path.name
    end

    def segment_url(path)
      draft_path(@draft, path: path.to_s)
    end

    def current?(path)
      path.to_s == @path.to_s
    end

    def link_data
      { turbo_frame: @turbo_frame, turbo_action: "advance" }
    end
  end
end
