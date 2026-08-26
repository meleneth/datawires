# frozen_string_literal: true

class SourceCredential < ApplicationRecord
  belongs_to :domain
  has_many :sources, dependent: :nullify

  validates :name, presence: true, uniqueness: { scope: :domain_id }
  validates :encrypted_payload, presence: true

  def secret=(value)
    self.encrypted_payload = encryptor.encrypt_and_sign(value.to_json)
  end

  def secret
    JSON.parse(encryptor.decrypt_and_verify(encrypted_payload))
  end

  private

  def encryptor
    key = ActiveSupport::KeyGenerator.new(Rails.application.secret_key_base).generate_key("datawires-source-credentials", 32)
    ActiveSupport::MessageEncryptor.new(key)
  end
end
