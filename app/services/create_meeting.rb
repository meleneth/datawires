# frozen_string_literal: true

class CreateMeeting
  Result = Data.define(:meeting, :document, :draft)

  def self.call(body:, title:, scheduled_at:, actor:)
    new(body:, title:, scheduled_at:, actor:).call
  end

  def initialize(body:, title:, scheduled_at:, actor:)
    raise ArgumentError, "body must be a Body" unless body.is_a?(Body)
    raise ArgumentError, "actor is required" unless actor

    @body = body
    @title = title.to_s.strip
    @scheduled_at = scheduled_at.in_time_zone
    @actor = actor
  end

  def call
    ApplicationRecord.transaction do
      meeting_id = SecureRandom.uuid
      stream = body.domain.event_streams.create!(
        stream_type: "meeting",
        subject_id: meeting_id
      )
      document = body.domain.documents.create!(
        key: next_key,
        title:,
        schema_document: meeting_schema_document
      )
      revision = document.revisions.create!(
        body: {
          "title" => title,
          "body_id" => body.id,
          "scheduled_at" => scheduled_at.iso8601
        },
        message: "Schedule meeting #{title}",
        created_by: actor
      )
      document.update!(head_revision: revision)
      meeting = Meeting.create!(
        id: meeting_id,
        body:,
        meeting_document: document,
        event_stream: stream
      )
      Result.new(meeting:, document:, draft: document.draft_for(actor:))
    end
  end

  private

  attr_reader :body, :title, :scheduled_at, :actor

  def next_key
    base = title.parameterize.presence || "meeting"
    return base unless body.domain.documents.exists?(key: base)

    index = 2
    index += 1 while body.domain.documents.exists?(key: "#{base}-#{index}")
    "#{base}-#{index}"
  end

  def meeting_schema_document
    existing = body.domain.documents.find_by(key: Meetings::Schema::KEY)
    return existing if existing&.body == Meetings::Schema::BODY
    raise ArgumentError, "meeting is not the Datawires Meeting schema" if existing

    document = body.domain.documents.create!(key: Meetings::Schema::KEY, title: "Meeting")
    revision = document.revisions.create!(
      body: Meetings::Schema::BODY,
      message: "Create Meeting schema",
      created_by: actor
    )
    document.update!(head_revision: revision)
    SchemaWrapper.create!(document:)
    document
  end
end
