# frozen_string_literal: true

ENV["RAILS_ENV"] = "test"
ENV["PORT"] ||= "31337"
ENV["HOST"] ||= "127.0.0.1"

system("bundle", "exec", "rails", "db:prepare") || abort("Failed to prepare test database")
system("bundle", "exec", "rails", "runner", "script/playwright_seed_wizard_game.rb") || abort("Failed to seed wizard game")
system("bundle", "exec", "rails", "runner", "script/playwright_seed_builder_flow.rb") || abort("Failed to seed builder flow")
exec("bundle", "exec", "rails", "server", "-b", ENV.fetch("HOST"), "-p", ENV.fetch("PORT"))
