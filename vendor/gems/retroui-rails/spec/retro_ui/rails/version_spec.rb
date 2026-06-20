# frozen_string_literal: true

require "spec_helper"

RSpec.describe RetroUI::Rails do
  it "has a version" do
    expect(RetroUI::Rails::VERSION).to match(/\A\d+\.\d+\.\d+\z/)
  end
end
