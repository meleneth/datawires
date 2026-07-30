# frozen_string_literal: true

class EventStream < ApplicationRecord
  belongs_to :domain
  has_many :event_records,
           -> { order(:sequence) },
           dependent: :restrict_with_exception,
           inverse_of: :event_stream

  validates :stream_type, presence: true
  validates :subject_id, presence: true
  validates :revision, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
end
