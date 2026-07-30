# frozen_string_literal: true

class EventRecord < ApplicationRecord
  belongs_to :event_stream, inverse_of: :event_records
  belongs_to :actor, class_name: "User", optional: true

  validates :sequence, numericality: { only_integer: true, greater_than: 0 }
  validates :event_type, :command_type, presence: true
  validates :event_version, :command_version, numericality: { only_integer: true, greater_than: 0 }
  validates :occurred_at, presence: true

  before_update :prevent_mutation
  before_destroy :prevent_mutation

  private

  def prevent_mutation
    raise ActiveRecord::ReadOnlyRecord, "Event records are append-only"
  end
end
