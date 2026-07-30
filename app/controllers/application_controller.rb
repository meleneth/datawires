class ApplicationController < ActionController::Base
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  include Authorization

  DEV_USER_ID = "18ed5b72-a961-486e-a6f3-fbdd8c8e2398".freeze
  DEFAULT_KEYSTONE_URL = "https://keystone.deva.station".freeze
  DEFAULT_OIDC_ISSUER = "https://iam.deva.station/realms/devastation".freeze
  DEFAULT_OIDC_CLIENT_ID = "devastation-demo".freeze
  DEFAULT_LOGOUT_REDIRECT_URL = "https://datawires.deva.station/oauth2/sign_in".freeze
  DEFAULT_KEYSTONE_ID_HEADERS = %w[
    HTTP_X_KEYSTONE_USER_ID
    HTTP_X_FORWARDED_USER
    HTTP_X_REMOTE_USER
    REMOTE_USER
  ].freeze
  DEFAULT_KEYSTONE_NAME_HEADERS = %w[
    HTTP_X_KEYSTONE_USER_NAME
    HTTP_X_FORWARDED_PREFERRED_USERNAME
    HTTP_X_FORWARDED_USER
    HTTP_X_REMOTE_USER
    REMOTE_USER
  ].freeze
  DEFAULT_KEYSTONE_EMAIL_HEADERS = %w[HTTP_X_KEYSTONE_USER_EMAIL HTTP_X_FORWARDED_EMAIL].freeze
  DEFAULT_KEYSTONE_AVATAR_HEADERS = %w[HTTP_X_KEYSTONE_USER_AVATAR].freeze

  private

  def current_user
    current_actor.user
  end

  helper_method :current_user

  def current_actor
    @current_actor ||= Identity::ResolveActor.call(claims: identity_claims)
  end

  helper_method :current_actor

  def identity_claims
    external_id = request_header_value(keystone_id_headers)
    return dev_identity_claims unless external_id

    Identity::Claims.new(
      issuer: ENV.fetch("OIDC_ISSUER", DEFAULT_OIDC_ISSUER),
      subject: external_id,
      name: keystone_user_name(external_id),
      email: request_header_value(keystone_email_headers),
      avatar: request_header_value(keystone_avatar_headers),
      groups: comma_separated_header("HTTP_X_FORWARDED_GROUPS"),
      organization_hints: comma_separated_header("HTTP_X_KEYSTONE_ORGANIZATIONS"),
      administrative_roles: comma_separated_header("HTTP_X_FORWARDED_ROLES")
    )
  end

  def keystone_user_name(external_id)
    request_header_value(keystone_name_headers) ||
      request_header_value(keystone_email_headers) ||
      external_id
  end

  def dev_identity_claims
    Identity::Claims.new(
      issuer: "datawires:development",
      subject: DEV_USER_ID,
      name: "devUser",
      avatar: "https://api.dicebear.com/7.x/pixel-art/png?seed=devUser"
    )
  end

  def comma_separated_header(name)
    request.headers[name].to_s.split(",").map(&:strip).reject(&:blank?)
  end

  def visible_domains
    current_user.visible_domains
  end

  def find_visible_domain!(id)
    visible_domains.find(id)
  end

  def require_visible_domain!(domain)
    raise ActiveRecord::RecordNotFound unless domain.visible_to?(current_user)

    domain
  end

  def keystone_id_headers
    env_headers("KEYSTONE_USER_ID_HEADER", DEFAULT_KEYSTONE_ID_HEADERS)
  end

  def keystone_name_headers
    env_headers("KEYSTONE_USER_NAME_HEADER", DEFAULT_KEYSTONE_NAME_HEADERS)
  end

  def keystone_email_headers
    env_headers("KEYSTONE_USER_EMAIL_HEADER", DEFAULT_KEYSTONE_EMAIL_HEADERS)
  end

  def keystone_avatar_headers
    env_headers("KEYSTONE_USER_AVATAR_HEADER", DEFAULT_KEYSTONE_AVATAR_HEADERS)
  end

  def env_headers(key, defaults)
    configured_headers = ENV.fetch(key, nil).to_s.split(",").filter_map { |value| env_header_name(value) }
    configured_headers.presence || defaults
  end

  def env_header_name(value)
    value.presence&.upcase&.tr("-", "_")&.then do |header|
      header.start_with?("HTTP_", "REMOTE_") ? header : "HTTP_#{header}"
    end
  end

  def request_header_value(headers)
    headers.lazy.filter_map { |header| request.env.fetch(header, nil).presence }.first
  end

  def keystone_url
    ENV.fetch("KEYSTONE_URL", DEFAULT_KEYSTONE_URL)
  end
  helper_method :keystone_url

  def logout_url
    provider_logout_url = "#{ENV.fetch("OIDC_ISSUER", DEFAULT_OIDC_ISSUER)}/protocol/openid-connect/logout"
    provider_logout_query = {
      client_id: ENV.fetch("OIDC_CLIENT_ID", DEFAULT_OIDC_CLIENT_ID),
      post_logout_redirect_uri: ENV.fetch("LOGOUT_REDIRECT_URL", DEFAULT_LOGOUT_REDIRECT_URL)
    }.to_query
    provider_logout_query = "id_token_hint={id_token}&#{provider_logout_query}"

    "/oauth2/sign_out?#{ { rd: "#{provider_logout_url}?#{provider_logout_query}" }.to_query }"
  end
  helper_method :logout_url
end
