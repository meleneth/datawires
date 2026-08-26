# frozen_string_literal: true

module Sources
  class BodyValidator
    attr_reader :errors

    def initialize(body)
      @body = body
      @errors = []
      validate
    end

    def valid?
      errors.empty?
    end

    private

    attr_reader :body

    def validate
      return errors << "body must be an object" unless body.is_a?(Hash)

      errors << "version must be 1" unless body["version"] == 1
      errors << "title must be a non-empty string" unless body["title"].to_s.present?
      provider = Datawires::Providers.sources.fetch(body["adapter"])
      if provider
        errors.concat(provider.validate(body["config"], path: "config"))
      else
        errors << "adapter is not registered: #{body['adapter']}"
      end
      validate_schedule
      errors << "observation must be an object" unless body["observation"].nil? || body["observation"].is_a?(Hash)
    end

    def validate_schedule
      schedule = body["schedule"]
      return if schedule.nil?
      return errors << "schedule must be an object" unless schedule.is_a?(Hash)

      interval = schedule["every_seconds"]
      return if interval.is_a?(Integer) && interval >= 60

      errors << "schedule.every_seconds must be an integer of at least 60"
    end
  end
end
