# frozen_string_literal: true

module Navigation
  module Schemas
    class NavRibbonComponent < ApplicationComponent
      def initialize(domain:, document:, draft:, path:, turbo_frame:)
        @domain = domain
        @document = document
        @draft = draft
        @path = ::Schemas::Path.new(path)
        @turbo_frame = turbo_frame
        @nav = ::Schemas::Nav.new(@draft.body)
      end

      def segments
        paths = [ ::Schemas::Path.new ]
        current = ::Schemas::Path.new

        @path.tokens.each do |token|
          current = current.child(token)
          paths << current
        end

        paths
      end

      def child_links
        @nav.object_keys_at(@path.to_s).map do |key|
          child_path = @path.child(key)
          [ key, draft_path(@draft, path: child_path.to_s) ]
        end
      end

      def segment_label(path)
        path.root? ? @document.title.presence || @document.key : path.tokens.last
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
end
