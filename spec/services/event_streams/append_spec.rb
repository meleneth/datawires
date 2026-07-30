# frozen_string_literal: true

require "rails_helper"

RSpec.describe EventStreams::Append do
  it "atomically appends ordered versioned events with provenance" do
    stream = create(:event_stream)
    command = build_command(stream:, expected_revision: 0)
    events = [
      Events::Data.new(type: "MeetingOpened", version: 1, payload: { "body_id" => SecureRandom.uuid }),
      Events::Data.new(
        type: "QuorumEstablished",
        version: 2,
        provenance: {
          "identity" => { "issuer" => "spoofed" },
          "command" => { "payload" => { "spoofed" => true } },
          "rule" => "default-quorum-v1"
        }
      )
    ]

    result = described_class.call(stream:, command:, events:)

    expect(result.revision).to eq(2)
    expect(result.records.map(&:sequence)).to eq([ 1, 2 ])
    expect(result.records.map(&:event_version)).to eq([ 1, 2 ])
    expect(result.records.last.provenance).to include(
      "command" => include(
        "payload" => {},
        "expected_revision" => 0,
        "timestamp" => command.timestamp.iso8601
      ),
      "identity" => include("issuer" => "spec"),
      "rule" => "default-quorum-v1"
    )
    expect(stream.reload.revision).to eq(2)
  end

  it "returns the original records when a command is retried" do
    stream = create(:event_stream)
    command = build_command(stream:, expected_revision: 0)
    event = Events::Data.new(type: "MeetingOpened", version: 1)
    first = described_class.call(stream:, command:, events: [ event ])

    retried = described_class.call(stream: stream.reload, command:, events: [ event ])

    expect(retried).to be_idempotent
    expect(retried.records).to eq(first.records)
    expect(stream.reload.revision).to eq(1)
  end

  it "rejects reuse of a command id with different command content" do
    stream = create(:event_stream)
    command = build_command(stream:, expected_revision: 0)
    event = Events::Data.new(type: "MeetingOpened", version: 1)
    described_class.call(stream:, command:, events: [ event ])
    changed_command = command.with(payload: { "changed" => true })

    expect {
      described_class.call(stream: stream.reload, command: changed_command, events: [ event ])
    }.to raise_error(EventStreams::IdempotencyConflict, /already used with different content/)
    expect(stream.reload.revision).to eq(1)
  end

  it "rejects a stale expected revision without appending" do
    stream = create(:event_stream, revision: 1)
    command = build_command(stream:, expected_revision: 0)
    count = EventRecord.count

    expect do
      described_class.call(
        stream:,
        command:,
        events: [ Events::Data.new(type: "MeetingOpened", version: 1) ]
      )
    end.to raise_error(EventStreams::Conflict) { |error|
      expect(error.actual_revision).to eq(1)
    }
    expect(EventRecord.count).to eq(count)
  end

  def build_command(stream:, expected_revision:)
    user = create(:user)
    actor = ActorContext.new(
      user:,
      claims: Identity::Claims.new(issuer: "spec", subject: user.id, name: "Actor")
    )
    Commands::Envelope.new(
      id: SecureRandom.uuid,
      type: "open_meeting",
      version: 1,
      stream_id: stream.id,
      expected_revision:,
      actor:,
      timestamp: Time.current,
      correlation_id: SecureRandom.uuid
    )
  end
end
