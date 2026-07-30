# frozen_string_literal: true

require "rails_helper"

RSpec.describe EventRecord, type: :model do
  it "cannot be updated or destroyed" do
    record = append_event

    expect { record.update!(payload: { "changed" => true }) }.to raise_error(ActiveRecord::ReadOnlyRecord)
    expect { record.destroy! }.to raise_error(ActiveRecord::ReadOnlyRecord)
  end

  def append_event
    stream = create(:event_stream)
    actor = create(:user)
    context = ActorContext.new(
      user: actor,
      claims: Identity::Claims.new(issuer: "spec", subject: actor.id, name: "Actor")
    )
    command = Commands::Envelope.new(
      id: SecureRandom.uuid,
      type: "test",
      version: 1,
      stream_id: stream.id,
      expected_revision: 0,
      actor: context,
      timestamp: Time.current
    )
    EventStreams::Append.call(
      stream:,
      command:,
      events: [ Events::Data.new(type: "Tested", version: 1) ]
    ).records.first
  end
end
