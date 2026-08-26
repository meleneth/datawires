# frozen_string_literal: true

require "base64"

class DocumentImagesController < ApplicationController
  ALLOWED_CONTENT_TYPES = %w[image/png image/jpeg image/webp].freeze

  def show
    document = Document.includes(:domain, :head_revision).find(params.expect(:document_id))
    require_visible_domain!(document.domain)
    body = document.body
    content_type = body["content_type"]
    raise ActiveRecord::RecordNotFound unless ALLOWED_CONTENT_TYPES.include?(content_type)

    send_data Base64.strict_decode64(body.fetch("data")), type: content_type, disposition: "inline",
      filename: "#{document.key || document.id}.#{extension_for(content_type)}"
  rescue KeyError, ArgumentError
    raise ActiveRecord::RecordNotFound
  end

  private

  def extension_for(content_type)
    { "image/png" => "png", "image/jpeg" => "jpg", "image/webp" => "webp" }.fetch(content_type)
  end
end
