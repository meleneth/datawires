# frozen_string_literal: true

require "bundler/setup"
ENV["RAILS_ENV"] ||= "test"

require "retro_ui/rails/erb_compat"
require_relative "dummy/config/environment"
require "rspec/rails"
require "rails/generators/testing/behavior"
require "fileutils"
require "capybara/rspec"
require "nokogiri"

Dir[File.expand_path("../support/**/*.rb", __FILE__)].sort.each { |file| require file }

RSpec.configure do |config|
  config.include Rails::Generators::Testing::Behavior, type: :generator
  config.include FileUtils, type: :generator

  config.expect_with :rspec do |expectations|
    expectations.syntax = :expect
  end
end
