# frozen_string_literal: true

class DomainArchivesController < ApplicationController
  before_action :set_domain, only: :show

  def show
    archive = DomainExports::Export.call(domain: @domain)
    send_data(
      JSON.pretty_generate(archive),
      filename: "#{@domain.name.parameterize.presence || "domain"}-archive.json",
      type: "application/json",
      disposition: "attachment"
    )
  end

  def create
    uploaded_file = params[:archive_file]
    raise ArgumentError, "Choose a domain archive JSON file." if uploaded_file.blank?

    archive = JSON.parse(uploaded_file.read)
    domain = DomainExports::Import.call(archive: archive, name: params[:name].presence)
    redirect_to domain, notice: "Domain archive was successfully imported."
  rescue ActiveRecord::RecordInvalid, ArgumentError, JSON::ParserError, KeyError => e
    redirect_to domains_path, alert: "Domain archive could not be imported: #{e.message}"
  end

  private

  def set_domain
    @domain = Domain.find(params.expect(:domain_id))
  end
end
