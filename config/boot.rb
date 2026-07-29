ENV["BUNDLE_GEMFILE"] ||= File.expand_path("../Gemfile", __dir__)

require "bundler/setup" # Set up gems listed in the Gemfile.
ENV["DISABLE_BOOTSNAP_COMPILE_CACHE"] = "1" if defined?(Coverage) && Coverage.running?
require "bootsnap/setup" unless ENV["DISABLE_BOOTSNAP"] # Speed up boot time by caching expensive operations.
