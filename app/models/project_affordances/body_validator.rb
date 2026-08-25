# frozen_string_literal: true

module ProjectAffordances
  class BodyValidator
    LINK_KINDS = %w[domain repository_history schema document view board].freeze
    attr_reader :errors

    def initialize(body)
      @body = body
      @errors = []
      validate
    end

    def valid?
      errors.empty?
    end

    private

    attr_reader :body

    def validate
      return errors << "body must be an object" unless body.is_a?(Hash)

      errors << "version must be 1" unless body["version"] == 1
      errors << "title must be a non-empty string" unless non_empty_string?(body["title"])
      errors << "description must be a string" unless body["description"].nil? || body["description"].is_a?(String)
      validate_groups
    end

    def validate_groups
      groups = body["groups"]
      return errors << "groups must be an array" unless groups.is_a?(Array)

      groups.each_with_index do |group, group_index|
        path = "groups[#{group_index}]"
        unless group.is_a?(Hash)
          errors << "#{path} must be an object"
          next
        end
        errors << "#{path}.title must be a non-empty string" unless non_empty_string?(group["title"])
        validate_links(group["links"], path)
      end
    end

    def validate_links(links, path)
      return errors << "#{path}.links must be an array" unless links.is_a?(Array)

      links.each_with_index do |link, link_index|
        link_path = "#{path}.links[#{link_index}]"
        unless link.is_a?(Hash)
          errors << "#{link_path} must be an object"
          next
        end
        errors << "#{link_path}.kind must be one of: #{LINK_KINDS.join(', ')}" unless LINK_KINDS.include?(link["kind"])
        errors << "#{link_path}.title must be a non-empty string" unless non_empty_string?(link["title"])
      end
    end

    def non_empty_string?(value)
      value.is_a?(String) && value.present?
    end
  end
end
