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

    def move_column
      mutate("Reorder board columns") do |body|
        columns = body.fetch("columns", [])
        if params[:target_column_id].present?
          move_before!(columns, params.expect(:column_id), params.expect(:target_column_id))
        else
          move_entry!(columns, params.expect(:column_id), params.expect(:direction))
        end
      end
    end

    def move_card
      mutate("Reorder board cards") do |body|
        source = Array(body["columns"]).find { |column| column["id"] == params.expect(:column_id) }
        raise ArgumentError, "board column was not found" unless source

        target_id = params[:target_column_id].presence || source["id"]
        target = Array(body["columns"]).find { |column| column["id"] == target_id }
        raise ArgumentError, "target board column was not found" unless target

        card = source.fetch("cards").find { |candidate| candidate["id"] == params.expect(:card_id) }
        raise ArgumentError, "board card was not found" unless card

        if target == source && params[:target_card_id].present?
          move_before!(source["cards"], card["id"], params.expect(:target_card_id))
        elsif target == source
          move_entry!(source["cards"], card["id"], params.expect(:direction))
        else
          source["cards"].delete(card)
          target_card = target["cards"].find { |candidate| candidate["id"] == params[:target_card_id] }
          if target_card
            target["cards"].insert(target["cards"].index(target_card), card)
          else
            target["cards"] << card
          end
        end
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
      raw = params.permit(:document_key, :view_affordance, :schema_key, :action_id, :metric_key, :query_key, :source_id,
        :renderer, :statistic, :aggregate, :bucket_seconds, :window_seconds, :dimensions).to_h.compact_blank
      if raw["dimensions"].present?
        parsed = JSON.parse(raw["dimensions"])
        raise ArgumentError, "dimensions must be a JSON object" unless parsed.is_a?(Hash)

        raw["dimensions"] = parsed
      end
      raw
    rescue JSON::ParserError
      raise ArgumentError, "dimensions must be valid JSON"
    end

    def move_entry!(entries, id, direction)
      index = entries.index { |entry| entry["id"] == id }
      raise ArgumentError, "board item was not found" unless index

      target = direction == "up" ? index - 1 : index + 1 if %w[up down].include?(direction)
      raise ArgumentError, "board item cannot be moved #{direction}" unless target&.between?(0, entries.length - 1)

      entries[index], entries[target] = entries[target], entries[index]
    end

    def move_before!(entries, id, target_id)
      entry = entries.find { |candidate| candidate["id"] == id }
      target = entries.find { |candidate| candidate["id"] == target_id }
      raise ArgumentError, "board item was not found" unless entry && target
      return if entry == target

      entries.delete(entry)
      entries.insert(entries.index(target), entry)
    end
  end
end
