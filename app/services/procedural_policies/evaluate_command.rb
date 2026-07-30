# frozen_string_literal: true

module ProceduralPolicies
  class EvaluateCommand
    class Rejected < StandardError; end

    Result = Data.define(:event_payload, :projection_effects)

    def self.call(meeting:, command:, definition:, projection:)
      new(meeting:, command:, definition:, projection:).call
    end

    def initialize(meeting:, command:, definition:, projection:)
      @meeting = meeting
      @command = command
      @definition = definition
      @projection = projection
    end

    def call
      resolve_resources
      definition.conditions.each { |condition| evaluate_condition(condition) }
      Result.new(
        event_payload: command.payload.deep_merge(resolve_value(definition.event_payload)),
        projection_effects: definition.effects.map { |effect| resolve_value(effect) }
      )
    end

    private

    attr_reader :meeting, :command, :definition, :projection, :resources

    def resolve_resources
      @resources = definition.resources.to_h do |name, descriptor|
        [ name, resolve_resource(descriptor) ]
      end
    end

    def resolve_resource(descriptor)
      Resources.resolve(
        type: descriptor.fetch("type"),
        id: resolve_value(descriptor.fetch("id"))
      )
    rescue Resources::NotFound, Resources::UnknownType => e
      reject!(e.message)
    end

    def evaluate_condition(condition)
      value = resolve_value(condition["value"])
      state = projection.public_send(condition["field"]) if condition["field"]
      valid = case condition["op"]
      when "blank" then state.blank?
      when "equals" then state == value
      when "collection_includes" then collection_matches?(state, condition["match_field"], value)
      when "collection_excludes" then !collection_matches?(state, condition["match_field"], value)
      when "resource_equals" then resource_attribute(condition) == value
      when "stack_empty" then Array(state).empty?
      when "stack_present" then Array(state).any?
      when "stack_top_equals" then stack_top_value(state, condition["match_field"]) == value
      else reject!("Policy condition is not registered.")
      end
      return if valid

      reject!(condition["reason"].presence || condition_failure_reason(condition["op"]))
    end

    def collection_matches?(collection, field, value)
      Array(collection).any? { |entry| entry[field] == value }
    end

    def resource_attribute(condition)
      resources.fetch(condition.fetch("resource")).fetch(condition.fetch("attribute"))
    end

    def stack_top_value(stack, field)
      value = Array(stack).last
      field ? value&.fetch(field, nil) : value
    end

    def resolve_value(value)
      return value.map { |entry| resolve_value(entry) } if value.is_a?(Array)
      return value unless value.is_a?(Hash)
      return value.transform_values { |entry| resolve_value(entry) } unless binding?(value)

      case value["source"]
      when "actor_id" then command.actor.user.id
      when "literal" then value["value"]
      when "meeting_body_id" then meeting.body_id
      when "payload" then value["key"] ? command.payload[value["key"]] : command.payload
      when "payload_or_literal" then command.payload[value["key"]].presence || value["value"]
      when "resource" then resources.fetch(value.fetch("resource")).fetch(value.fetch("attribute"))
      when "timestamp" then command.timestamp
      when "timestamp_iso8601" then command.timestamp.iso8601
      else reject!("Policy binding source is not registered.")
      end
    end

    def binding?(value)
      value.is_a?(Hash) && value.key?("source")
    end

    def condition_failure_reason(operation)
      {
        "blank" => "Required state is not blank.",
        "equals" => "Current state does not match the required actor or value.",
        "collection_includes" => "Required related state was not found.",
        "collection_excludes" => "The action would duplicate existing state.",
        "resource_equals" => "The referenced resource is outside the Meeting scope.",
        "stack_empty" => "The stack must be empty.",
        "stack_present" => "The stack must not be empty.",
        "stack_top_equals" => "The immediately pending stack entry does not match."
      }.fetch(operation, "The procedural condition failed.")
    end

    def reject!(message)
      raise Rejected, message
    end
  end
end
