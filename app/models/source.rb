# frozen_string_literal: true

class Source < ApplicationRecord
  STATUSES = %w[idle queued running succeeded failed disabled].freeze

  belongs_to :domain
  belongs_to :source_document, class_name: "Document", inverse_of: :source
  belongs_to :source_credential, optional: true
  has_many :source_runs, dependent: :restrict_with_exception
  has_many :observations, dependent: :restrict_with_exception

  validates :status, inclusion: { in: STATUSES }
  validate :source_document_must_share_domain
  validate :source_document_must_use_source_schema
  validate :configuration_must_be_valid
  validate :credential_must_share_domain

  delegate :body, :head_revision, to: :source_document

  def adapter
    body["adapter"].to_s
  end

  def acquire_execution_lease(now: Time.current, ttl: 5.minutes)
    with_lock do
      return if leased_until&.>(now)

      token = SecureRandom.uuid
      update!(lease_token: token, leased_until: now + ttl)
      token
    end
  end

  def release_execution_lease(token)
    with_lock do
      return false unless lease_token == token

      update!(lease_token: nil, leased_until: nil)
      true
    end
  end

  private

  def source_document_must_share_domain
    return if source_document.blank? || source_document.domain == domain

    errors.add(:source_document, "must belong to the source domain")
  end

  def source_document_must_use_source_schema
    return if source_document.blank? || source_document.schema_document&.key == Sources::Schema::KEY

    errors.add(:source_document, "must use the Datawires Source schema")
  end

  def configuration_must_be_valid
    return if source_document.blank?

    Sources::BodyValidator.new(body).errors.each { |message| errors.add(:source_document, message) }
  end

  def credential_must_share_domain
    return if source_credential.blank? || source_credential.domain == domain

    errors.add(:source_credential, "must belong to the source domain")
  end
end
