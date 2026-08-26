# frozen_string_literal: true

module Boards
  class ConfigurationsController < ApplicationController
    before_action :set_board

    def update_layout
      mutate("Change board layout") { |body| body["layout"] = { "provider" => params.expect(:provider) } }
    end

    def add_column
      mutate("Add board column") do |body|
        body["columns"] ||= []
        body["columns"] << { "id" => unique_id(params.expect(:title), body["columns"]), "title" => params.expect(:title), "cards" => [] }
      end
    end

    def add_card
      mutate("Add board card") do |body|
        column = Array(body["columns"]).find { |candidate| candidate["id"] == params.expect(:column_id) }
        raise ArgumentError, "board column was not found" unless column

        column["cards"] << {
          "id" => unique_id(params.expect(:title), column["cards"]),
          "kind" => params.expect(:kind),
          "title" => params.expect(:title),
          "description" => params[:description].to_s,
          "config" => card_config
        }
      end
    end

    def remove_card
      mutate("Remove board card") do |body|
        column = Array(body["columns"]).find { |candidate| candidate["id"] == params.expect(:column_id) }
        raise ArgumentError, "board column was not found" unless column

        column["cards"].reject! { |card| card["id"] == params.expect(:card_id) }
      end
    end

    private

    def set_board
      @board = Board.includes(:board_document, schema_wrapper: :document).find(params[:board_id])
      require_visible_domain!(@board.schema_wrapper.domain)
    end

    def mutate(message, &block)
      ConfigurationMutation.call(board: @board, actor: current_user, message:, &block)
      redirect_to board_path(@board), notice: message
    rescue ArgumentError => e
      redirect_to board_path(@board), alert: e.message
    end

    def unique_id(title, entries)
      base = title.to_s.parameterize.presence || "item"
      ids = entries.pluck("id")
      return base unless ids.include?(base)

      index = 2
      index += 1 while ids.include?("#{base}-#{index}")
      "#{base}-#{index}"
    end

    def card_config
      raw = params.permit(:document_key, :view_affordance, :schema_key, :action_id, :metric_key, :source_id,
        :renderer, :statistic, :aggregate, :bucket_seconds).to_h
      raw.compact_blank
    end
  end
end
