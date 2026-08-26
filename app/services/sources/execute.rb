# frozen_string_literal: true

module Sources
  class Execute
    def self.call(source:, trigger:, actor: nil, idempotency_key: SecureRandom.uuid)
      new(source:, trigger:, actor:, idempotency_key:).call
    end

    def initialize(source:, trigger:, actor:, idempotency_key:)
      @source = source
      @trigger = trigger
      @actor = actor
      @idempotency_key = idempotency_key
    end

    def call
      revision = source.head_revision
      provider = Datawires::Providers.sources.fetch(revision.body["adapter"])
      raise ArgumentError, "source adapter is not registered" unless provider

      run = source.source_runs.find_or_create_by!(idempotency_key:) do |candidate|
        candidate.configuration_revision = revision
        candidate.triggered_by = actor
        candidate.trigger = trigger
        candidate.adapter = source.adapter
        candidate.adapter_version = provider::VERSION
      end
      return run unless %w[pending retrying].include?(run.status)

      started_at = Time.current
      run.update!(status: "running", started_at:)
      source.update!(status: "running", last_started_at: started_at)
      result = provider.new(configuration: revision.body.fetch("config"), credential: source.source_credential&.secret).call
      observations = append_observations(run:, revision:, items: result.items)
      finished_at = Time.current
      run.update!(status: "succeeded", finished_at:, observation_count: observations.length, metadata: result.metadata)
      source.update!(status: "succeeded", last_succeeded_at: finished_at, last_error: nil,
        next_run_at: next_run_at(revision.body, finished_at))
      run
    rescue StandardError => e
      fail_run(run, e) if run&.persisted?
      raise
    end

    private

    attr_reader :source, :trigger, :actor, :idempotency_key

    def append_observations(run:, revision:, items:)
      definition = revision.body.fetch("observation", {})
      ApplicationRecord.transaction do
        items.map do |item|
          now = Time.current
          observed_at = time_at(item, definition["observed_at_pointer"]) || now
          source.observations.create!(
            domain: source.domain,
            source_run: run,
            configuration_revision: revision,
            observation_type: definition["type"].presence || "json",
            metric_key: definition["metric_key"],
            unit: definition["unit"],
            numeric_value: numeric_at(item, definition["value_pointer"]),
            dimensions: dimensions_for(item, definition["dimensions"]),
            payload: item,
            observed_at:,
            effective_at: observed_at,
            recorded_at: now,
            provenance: {
              "source_id" => source.id,
              "source_document_id" => source.source_document_id,
              "configuration_revision_id" => revision.id,
              "source_run_id" => run.id,
              "adapter" => run.adapter,
              "adapter_version" => run.adapter_version
            }
          )
        end
      end
    end

    def value_at(item, pointer)
      return if pointer.blank?

      JsonPtr.get(item, pointer)
    rescue KeyError, TypeError
      nil
    end

    def numeric_at(item, pointer)
      value = value_at(item, pointer)
      BigDecimal(value.to_s) unless value.nil?
    rescue ArgumentError
      nil
    end

    def time_at(item, pointer)
      value = value_at(item, pointer)
      Time.zone.parse(value.to_s) if value.present?
    rescue ArgumentError
      nil
    end

    def dimensions_for(item, definitions)
      return {} unless definitions.is_a?(Hash)

      definitions.transform_values { |pointer| value_at(item, pointer) }.compact
    end

    def next_run_at(body, from)
      seconds = body.dig("schedule", "every_seconds")
      from + seconds.seconds if seconds
    end

    def fail_run(run, error)
      finished_at = Time.current
      run.update!(status: "failed", finished_at:, error_class: error.class.name, error_message: error.message)
      source.update!(status: "failed", last_failed_at: finished_at, last_error: error.message)
    end
  end
end
