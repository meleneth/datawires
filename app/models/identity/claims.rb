# frozen_string_literal: true

module Identity
  Claims = Data.define(
    :issuer,
    :subject,
    :name,
    :email,
    :avatar,
    :groups,
    :organization_hints,
    :administrative_roles
  ) do
    def initialize(issuer:, subject:, name:, email: nil, avatar: nil, groups: [], organization_hints: [], administrative_roles: [])
      super(
        issuer: issuer.to_s.freeze,
        subject: subject.to_s.freeze,
        name: name.to_s.freeze,
        email: email&.to_s&.freeze,
        avatar: avatar&.to_s&.freeze,
        groups: Array(groups).map { |value| value.to_s.freeze }.uniq.sort.freeze,
        organization_hints: Array(organization_hints).map { |value| value.to_s.freeze }.uniq.sort.freeze,
        administrative_roles: Array(administrative_roles).map { |value| value.to_s.freeze }.uniq.sort.freeze
      )
      freeze
    end
  end
end
