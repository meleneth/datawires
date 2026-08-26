# frozen_string_literal: true

require "rails_helper"

RSpec.describe BoardsHelper do
  describe "#format_board_statistic" do
    it "keeps statistics compact and preserves missing values" do
      presenter = Class.new do
        include ActionView::Helpers::NumberHelper
        include BoardsHelper
      end.new

      expect(presenter.format_board_statistic(BigDecimal("48.142857142857"))).to eq("48.14")
      expect(presenter.format_board_statistic(BigDecimal("69.0"))).to eq("69")
      expect(presenter.format_board_statistic(nil)).to eq("—")
    end
  end
end
