# app/services/documents/diff.rb
# frozen_string_literal: true

module Documents
  class Diff
    Row = Data.define(:path, :kind, :before, :after)

    def self.rows(before:, after:)
      new(before:, after:).rows
    end

    def initialize(before:, after:)
      @before = before
      @after = after
    end

    def rows
      build_rows(before: @before, after: @after, path: [])
    end

    private

    def build_rows(before:, after:, path:)
      if before.is_a?(Hash) && after.is_a?(Hash)
        diff_hash(before:, after:, path:)
      elsif before.is_a?(Array) && after.is_a?(Array)
        diff_array(before:, after:, path:)
      elsif before == after
        []
      else
        [ Row.new(path: pointer(path), kind: :changed, before:, after:) ]
      end
    end

    def diff_hash(before:, after:, path:)
      keys = (before.keys + after.keys).uniq.sort

      keys.flat_map do |key|
        key_before = before.key?(key)
        key_after = after.key?(key)
        child_path = path + [ key ]

        if key_before && key_after
          build_rows(before: before[key], after: after[key], path: child_path)
        elsif key_before
          [
            Row.new(
              path: pointer(child_path),
              kind: :removed,
              before: before[key],
              after: nil
            )
          ]
        else
          [
            Row.new(
              path: pointer(child_path),
              kind: :added,
              before: nil,
              after: after[key]
            )
          ]
        end
      end
    end

    def diff_array(before:, after:, path:)
      max = [ before.length, after.length ].max

      (0...max).flat_map do |index|
        child_path = path + [ index.to_s ]
        has_before = index < before.length
        has_after = index < after.length

        if has_before && has_after
          build_rows(before: before[index], after: after[index], path: child_path)
        elsif has_before
          [
            Row.new(
              path: pointer(child_path),
              kind: :removed,
              before: before[index],
              after: nil
            )
          ]
        else
          [
            Row.new(
              path: pointer(child_path),
              kind: :added,
              before: nil,
              after: after[index]
            )
          ]
        end
      end
    end

    def pointer(segments)
      return "/" if segments.empty?

      "/" + segments.map { |segment| escape(segment) }.join("/")
    end

    def escape(segment)
      segment.to_s.gsub("~", "~0").gsub("/", "~1")
    end
  end
end
