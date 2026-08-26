# frozen_string_literal: true

require "net/http"

module Sources
  module Adapters
    class HttpJson
      VERSION = "1".freeze
      PERMITTED_HEADERS = %w[Accept Authorization User-Agent X-Api-Key].freeze

      def self.validate(config, path: "config")
        return [ "#{path} must be an object" ] unless config.is_a?(Hash)

        errors = []
        begin
          uri = URI.parse(config["url"].to_s)
          errors << "#{path}.url must use HTTP or HTTPS" unless %w[http https].include?(uri.scheme) && uri.host.present?
        rescue URI::InvalidURIError
          errors << "#{path}.url must be a valid URI"
        end
        errors << "#{path}.method must be GET" unless config.fetch("method", "GET") == "GET"
        errors
      end

      def initialize(configuration:, credential: nil)
        @configuration = configuration
        @credential = credential
      end

      def call
        uri = URI.parse(configuration.fetch("url"))
        request = Net::HTTP::Get.new(uri)
        headers.each { |name, value| request[name] = value }
        response = Net::HTTP.start(uri.host, uri.port, use_ssl: uri.scheme == "https",
          open_timeout: configuration.fetch("open_timeout", 5), read_timeout: configuration.fetch("read_timeout", 15)) do |http|
          http.request(request)
        end
        raise ResponseError, "HTTP #{response.code}" unless response.is_a?(Net::HTTPSuccess)

        payload = JSON.parse(response.body)
        selected = configuration["items_pointer"].present? ? JsonPtr.get(payload, configuration["items_pointer"]) : payload
        Result.new(items: selected.is_a?(Array) ? selected : [ selected ], metadata: { "http_status" => response.code.to_i })
      rescue JSON::ParserError => e
        raise ResponseError, "Response was not valid JSON: #{e.message}"
      end

      class ResponseError < StandardError; end

      private

      attr_reader :configuration, :credential

      def headers
        configured = configuration.fetch("headers", {}).slice(*PERMITTED_HEADERS)
        configured.merge(credential&.fetch("headers", {})&.slice(*PERMITTED_HEADERS) || {})
      end
    end
  end
end
