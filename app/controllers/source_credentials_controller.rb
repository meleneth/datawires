# frozen_string_literal: true

class SourceCredentialsController < ApplicationController
  before_action :set_domain
  before_action :set_credential, only: %i[edit update]

  def index
    @credentials = @domain.source_credentials.order(:name)
  end

  def new
    @credential = @domain.source_credentials.new
  end

  def edit
  end

  def create
    @credential = @domain.source_credentials.new(name: credential_params.fetch(:name))
    @credential.secret = secret_payload
    @credential.save!
    redirect_to domain_source_credentials_path(@domain), notice: "Credential was created."
  rescue ActiveRecord::RecordInvalid, KeyError => e
    flash.now[:alert] = e.message
    render :new, status: :unprocessable_entity
  end

  def update
    if ActiveModel::Type::Boolean.new.cast(credential_params[:revoke])
      @credential.revoke!
      notice = "Credential was revoked."
    else
      @credential.update!(name: credential_params.fetch(:name))
      @credential.rotate!(secret_payload) if credential_params[:secret].present?
      notice = "Credential was updated."
    end
    redirect_to domain_source_credentials_path(@domain), notice:
  rescue ActiveRecord::RecordInvalid, KeyError => e
    flash.now[:alert] = e.message
    render :edit, status: :unprocessable_entity
  end

  private

  def set_domain
    @domain = find_visible_domain!(params.expect(:domain_id))
    raise ActiveRecord::RecordNotFound unless @domain.project?
  end

  def set_credential
    @credential = @domain.source_credentials.find(params.expect(:id))
  end

  def credential_params
    params.expect(source_credential: %i[name secret revoke])
  end

  def secret_payload
    value = credential_params.fetch(:secret)
    raise KeyError, "secret is required" if value.blank?

    { "headers" => { "Authorization" => value } }
  end
end
