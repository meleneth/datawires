# frozen_string_literal: true

module EventStreams
  class Conflict < StandardError
    attr_reader :expected_revision, :actual_revision

    def initialize(expected_revision:, actual_revision:)
      @expected_revision = expected_revision
      @actual_revision = actual_revision
      super("expected stream revision #{expected_revision}, got #{actual_revision}")
    end
  end

  class Append
    Result = Data.define(:records, :revision, :idempotent) do
      def idempotent?
        idempotent
      end
    end

    def self.call(stream:, command:, events:)
      new(stream:, command:, events:).call
    end

    def initialize(stream:, command:, events:)
      raise ArgumentError, "stream must be an EventStream" unless stream.is_a?(EventStream)
      raise ArgumentError, "command must be a Commands::Envelope" unless command.is_a?(Commands::Envelope)
      raise ArgumentError, "command stream does not match" unless command.stream_id == stream.id
      raise ArgumentError, "events must not be empty" if events.blank?
      raise ArgumentError, "events must be Events::Data" unless events.all? { |event| event.is_a?(Events::Data) }

      @stream = stream
      @command = command
      @events = events
    end

    def call
      EventStream.transaction do
        stream.lock!
        existing = stream.event_records.where(command_id: command.id).order(:sequence).to_a
        return Result.new(records: existing, revision: stream.revision, idempotent: true) if existing.any?

        if stream.revision != command.expected_revision
          raise Conflict.new(expected_revision: command.expected_revision, actual_revision: stream.revision)
        end

        records = events.each_with_index.map { |event, index| append_event(event, stream.revision + index + 1) }
        stream.update!(revision: stream.revision + records.length)
        Result.new(records:, revision: stream.revision, idempotent: false)
      end
    end

    private

    attr_reader :stream, :command, :events

    def append_event(event, sequence)
      stream.event_records.create!(
        sequence:,
        event_type: event.type,
        event_version: event.version,
        payload: event.payload,
        command_id: command.id,
        command_type: command.type,
        command_version: command.version,
        correlation_id: command.correlation_id,
        causation_id: command.causation_id,
        actor: command.actor.user,
        occurred_at: command.timestamp,
        provenance: base_provenance.deep_merge(event.provenance)
      )
    end

    def base_provenance
      {
        "identity" => {
          "issuer" => command.actor.claims.issuer,
          "subject" => command.actor.claims.subject
        }
      }
    end
  end
end
