# frozen_string_literal: true

module ProceduralPolicies
  class BodyValidator
    CAPABILITIES = Authorization::BodyPolicy::ROLE_CAPABILITIES.keys.map(&:to_s).freeze
    STATUSES = %w[scheduled open adjourned].freeze
    PAYLOAD_TYPES = %w[array boolean string uuid].freeze
    EVENT_TYPES = %w[
      MeetingOpened
      AttendanceEstablished
      QuorumEstablished
      MeetingAdjourned
      RecognitionRequested
      MemberRecognized
      FloorRelinquished
      ProposalScheduled
    ].freeze

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
      unless body.is_a?(Hash)
        errors << "body must be an object"
        return
      end

      errors << "version must be 1" unless body["version"] == 1
      errors << "name must be a non-empty string" unless body["name"].is_a?(String) && body["name"].present?
      commands = body["commands"]
      unless commands.is_a?(Hash)
        errors << "commands must be an object"
        return
      end

      commands.each { |name, definition| validate_command(name, definition) }
    end

    def validate_command(name, definition)
      prefix = "commands.#{name}"
      errors << "#{prefix} name must be non-empty" if name.blank?
      unless definition.is_a?(Hash)
        errors << "#{prefix} must be an object"
        return
      end

      errors << "#{prefix}.capability must be registered" unless CAPABILITIES.include?(definition["capability"])
      statuses = definition["allowed_statuses"]
      errors << "#{prefix}.allowed_statuses must contain known statuses" unless statuses.is_a?(Array) && statuses.present? && (statuses - STATUSES).empty?
      errors << "#{prefix}.event_type must be registered" unless EVENT_TYPES.include?(definition["event_type"])
      errors << "#{prefix}.event_version must be positive" unless definition["event_version"].is_a?(Integer) && definition["event_version"].positive?
      validate_payload(definition["payload"], prefix)
    end

    def validate_payload(payload, prefix)
      return if payload.nil?
      unless payload.is_a?(Hash)
        errors << "#{prefix}.payload must be an object"
        return
      end

      payload.each do |key, type|
        errors << "#{prefix}.payload.#{key} must use a registered type" unless PAYLOAD_TYPES.include?(type)
      end
    end
  end
end
