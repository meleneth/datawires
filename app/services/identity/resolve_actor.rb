# frozen_string_literal: true

module Identity
  class ResolveActor
    def self.call(claims:)
      new(claims:).call
    end

    def initialize(claims:)
      raise ArgumentError, "claims must be Identity::Claims" unless claims.is_a?(Claims)
      raise ArgumentError, "issuer is required" if claims.issuer.blank?
      raise ArgumentError, "subject is required" if claims.subject.blank?

      @claims = claims
    end

    def call
      user = User.find_by(identity_issuer: claims.issuer, identity_subject: claims.subject)
      user ||= legacy_user
      user ||= User.new
      prevent_identity_remap!(user)

      user.assign_attributes(
        identity_issuer: claims.issuer,
        identity_subject: claims.subject,
        external_id: compatible_external_id(user),
        name: claims.name.presence || claims.subject,
        email: claims.email,
        avatar: claims.avatar
      )
      user.save! if user.new_record? || user.changed?
      ActorContext.new(user:, claims:)
    end

    private

    attr_reader :claims

    def legacy_user
      external = User.find_by(external_id: claims.subject)
      return external if external && identity_unclaimed_or_matching?(external)

      User.find_by(id: claims.subject)
    end

    def prevent_identity_remap!(user)
      return if user.identity_issuer.blank? && user.identity_subject.blank?
      return if user.identity_issuer == claims.issuer && user.identity_subject == claims.subject

      raise ArgumentError, "identity subject is already mapped to a different issuer"
    end

    def identity_unclaimed_or_matching?(user)
      (user.identity_issuer.blank? && user.identity_subject.blank?) ||
        (user.identity_issuer == claims.issuer && user.identity_subject == claims.subject)
    end

    def compatible_external_id(user)
      return user.external_id if user.external_id.present?
      return claims.subject unless User.where(external_id: claims.subject).where.not(id: user.id).exists?

      nil
    end
  end
end
