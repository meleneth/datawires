# frozen_string_literal: true

require_relative "lib/retro_ui/rails/version"

Gem::Specification.new do |spec|
  spec.name = "retroui-rails"
  spec.version = RetroUI::Rails::VERSION
  spec.authors = ["RetroUI Rails contributors"]
  spec.email = ["contributors@example.com"]

  spec.summary = "RetroUI components for Rails and ViewComponent."
  spec.description = "A Tailwind-first Rails/ViewComponent port of RetroUI, inspired by the original MIT-licensed RetroUI project by Arif Hossain and contributors."
  spec.homepage = "https://github.com/meleneth/retroui-rails"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 3.1.0"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = spec.homepage

  spec.files = Dir.chdir(__dir__) do
    Dir["{app,lib,spec}/**/*", "Gemfile", "LICENSE", "NOTICE.md", "README.md", "retroui-rails.gemspec"]
  end
  spec.require_paths = ["lib"]

  spec.add_dependency "rails", ">= 7.0", "< 9.0"
  spec.add_dependency "stimulus-rails", ">= 1.3"
  spec.add_dependency "view_component", ">= 3.0"

  spec.add_development_dependency "capybara"
  spec.add_development_dependency "nokogiri"
  spec.add_development_dependency "puma", ">= 6.0"
  spec.add_development_dependency "rspec-rails", "< 8.0"
  spec.add_development_dependency "tzinfo-data"
end
