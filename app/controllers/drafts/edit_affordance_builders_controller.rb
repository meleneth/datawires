# frozen_string_literal: true

module Drafts
  class EditAffordanceBuildersController < ApplicationController
    BUILDER_SPAN_RANGE = (1..12).freeze
    DEFAULT_FIELD_SPAN = 3
    WIDTHS = %w[narrow medium large full].freeze

    before_action :load_context

    def show
      @tab = tab_param
    end

    def row
      @tab = "row"
      @row_index = row_index_param
      @row = row_at!(@row_index)
      render :show
    end

    def cell
      @tab = "cell"
      @row_index = row_index_param
      @cell_index = cell_index_param
      @row = row_at!(@row_index)
      @cell = cell_at!(@row, @cell_index)
      render :show
    end

    def add_row
      body = deep_dup_json(@draft.body)
      ensure_main_screen(body)["rows"] << []
      @draft.update!(body: body)

      redirect_to draft_edit_affordance_builder_path(@draft, tab: "builder"),
        notice: "Row added."
    end

    def add_field
      @draft.update!(body: body_with_added_field)

      redirect_to draft_edit_affordance_builder_path(@draft, tab: "builder"),
        notice: "Field added."
    end

    def update_screen
      body = deep_dup_json(@draft.body)
      main_screen = ensure_main_screen(body)
      main_screen["width"] = params[:width].presence_in(WIDTHS) || "large"
      main_screen["default_span"] = normalized_span(params[:default_span])
      @draft.update!(body: body)

      redirect_to draft_edit_affordance_builder_path(@draft, tab: "builder"),
        notice: "Screen layout updated."
    end

    def update_raw
      @draft.update!(body: JSON.parse(params.require(:body_json)))

      redirect_to draft_edit_affordance_builder_path(@draft, tab: "raw"),
        notice: "Raw affordance JSON updated."
    rescue JSON::ParserError => e
      redirect_to draft_edit_affordance_builder_path(@draft, tab: "raw"),
        alert: "Invalid JSON: #{e.message}"
    end

    def destroy_affordance
      schema_wrapper = @schema_wrapper
      edit_document = @edit_affordance.edit_document

      ApplicationRecord.transaction do
        @edit_affordance.destroy!
        edit_document.reload
        edit_document.drafts.destroy_all
        edit_document.revisions.destroy_all
        edit_document.destroy!
      end

      redirect_to schema_path(schema_wrapper),
        notice: "Edit affordance deleted."
    end

    def delete_row
      body = deep_dup_json(@draft.body)
      rows = main_rows_for(body)
      index = row_index_param
      row_at!(index, rows: rows)
      rows.delete_at(index)
      @draft.update!(body: body)

      redirect_to draft_edit_affordance_builder_path(@draft, tab: "builder"),
        notice: "Row deleted."
    end

    def move_row
      body = deep_dup_json(@draft.body)
      rows = main_rows_for(body)
      row_index = row_index_param
      row_at!(row_index, rows: rows)
      target_index = target_row_index(row_index, params[:direction])
      unless target_index >= 0 && target_index < rows.length
        return redirect_to draft_edit_affordance_builder_path(@draft, tab: "builder"),
          alert: "Row cannot be moved #{params[:direction]}."
      end

      rows[row_index], rows[target_index] = rows[target_index], rows[row_index]
      @draft.update!(body: body)

      redirect_to draft_edit_affordance_builder_path(@draft, tab: "builder"),
        notice: "Row moved."
    end

    def delete_cell
      body = deep_dup_json(@draft.body)
      rows = main_rows_for(body)
      row_index = row_index_param
      cell_index = cell_index_param
      row = row_at!(row_index, rows: rows)
      cell_at!(row, cell_index)
      row.delete_at(cell_index)
      @draft.update!(body: body)

      redirect_to row_draft_edit_affordance_builder_path(@draft, row_index: row_index),
        notice: "Field deleted."
    end

    def move_cell
      body = deep_dup_json(@draft.body)
      rows = main_rows_for(body)
      row_index = row_index_param
      cell_index = cell_index_param
      row = row_at!(row_index, rows: rows)
      cell_at!(row, cell_index)
      target_index = target_cell_index(cell_index, params[:direction])
      unless target_index >= 0 && target_index < row.length
        return redirect_to row_draft_edit_affordance_builder_path(@draft, row_index: row_index),
          alert: "Field cannot be moved #{params[:direction]}."
      end

      row[cell_index], row[target_index] = row[target_index], row[cell_index]
      @draft.update!(body: body)

      redirect_to row_draft_edit_affordance_builder_path(@draft, row_index: row_index),
        notice: "Field moved."
    end

    private

    def load_context
      @draft = Draft.includes(document: :edit_affordance).find(params[:draft_id])
      @edit_affordance = @draft.document.edit_affordance
      raise ActiveRecord::RecordNotFound, "draft is not an edit affordance draft" unless @edit_affordance

      @schema_wrapper = @edit_affordance.schema_wrapper
      @schema_document = @schema_wrapper.document
      @domain = @schema_wrapper.domain
      @field_entries = field_entries
      @diagnostics = EditAffordances::BodyValidator.new(@draft.body).errors
      @preview_projection = preview_projection
      @main_screen = current_main_screen
      @rows = Array(@main_screen&.fetch("rows", []))
      @builder_width_class = width_class_for(@main_screen&.fetch("width", "large"))
    end

    def tab_param
      params[:tab].presence_in(%w[builder preview diagnostics raw]) || "builder"
    end

    def body_with_added_field
      body = deep_dup_json(@draft.body)
      main_screen = ensure_main_screen(body)
      target_row(main_screen) << field_cell_from_params
      body
    end

    def ensure_main_screen(body)
      body["version"] ||= 1
      body["start_screen"] ||= "main"
      body["commit_mode"] ||= "review_screen"
      body["subforms"] ||= []
      body["screens"] = Array(body["screens"])
      main_screen = body["screens"].find { |screen| screen.is_a?(Hash) && screen["id"] == "main" }
      return main_screen.tap { |screen| screen["rows"] = Array(screen["rows"]) } if main_screen

      body["screens"] << {
        "id" => "main",
        "title" => "Main",
        "columns" => 12,
        "default_span" => DEFAULT_FIELD_SPAN,
        "width" => "large",
        "rows" => []
      }
      body["screens"].last
    end

    def field_cell_from_params
      ptr = params.require(:ptr)
      widget = params[:widget].presence || "auto"
      field_entry = @field_entries.find { |entry| entry.ptr == ptr }
      cell = {
        "binding" => {
          "kind" => "document_ptr",
          "ptr" => ptr
        },
        "widget" => widget,
        "label" => ActiveModel::Type::Boolean.new.cast(params[:label])
      }
      cell["span"] = normalized_span(params[:span])
      cell["help"] = params[:help] if params[:help].present?
      cell["collection"] = collection_config_from_params if field_entry&.array?
      cell
    end

    def target_row(main_screen)
      rows = main_screen["rows"] = Array(main_screen["rows"])
      selected_index = params[:row_index].presence
      return append_row(rows) if selected_index == "new" || rows.empty?

      index = Integer(selected_index, 10)
      return rows[index] if index >= 0 && index < rows.length

      append_row(rows)
    rescue ArgumentError
      append_row(rows)
    end

    def append_row(rows)
      rows << []
      rows.last
    end

    def normalized_span(raw_span)
      span = raw_span.presence&.to_i || DEFAULT_FIELD_SPAN
      span.clamp(BUILDER_SPAN_RANGE.begin, BUILDER_SPAN_RANGE.end)
    end

    def collection_config_from_params
      config = EditAffordances::Collection.default_config.merge(
        "presentation" => params[:collection_presentation].presence || EditAffordances::Collection::DEFAULT_PRESENTATION,
        "creation" => params[:collection_creation].presence || EditAffordances::Collection::DEFAULT_CREATION,
        "delete" => params[:collection_delete].presence || EditAffordances::Collection::DEFAULT_POLICY,
        "reorder" => params[:collection_reorder].presence || EditAffordances::Collection::DEFAULT_POLICY,
        "item_title" => collection_binding_from_params("item_title", default: EditAffordances::Collection::DEFAULT_TITLE_BINDING),
        "item_subtitle" => collection_binding_from_params("item_subtitle", default: EditAffordances::Collection::DEFAULT_SUBTITLE_BINDING)
      )
      config["item_screen"] = params[:collection_item_screen] if params[:collection_item_screen].present?
      config
    end

    def collection_binding_from_params(prefix, default:)
      kind = params["#{prefix}_kind"].presence
      return default unless kind
      return { "kind" => "none" } if kind == "none"
      return { "kind" => "value_label" } if kind == "value_label"

      {
        "kind" => "property",
        "name" => params["#{prefix}_name"].presence || default["name"].presence || "name"
      }
    end

    def field_entries
      source = SchemaPreviewSource.new(schema_document: @schema_document, body: seeded_example_body)
      cursor = Documents::Cursor.new(source: source, path: "")
      collect_field_entries(SchemaPaths::Inventory.new(root_cursor: cursor), cursor)
    end

    def collect_field_entries(inventory, cursor)
      cursor.children.flat_map do |child|
        entry = inventory.entry_for(child)
        child.object? ? collect_field_entries(inventory, child) : [ entry ]
      end
    end

    def preview_projection
      source = SchemaPreviewSource.new(schema_document: @schema_document, body: seeded_example_body)
      cursor = Documents::Cursor.new(source: source, path: "")
      projection_affordance.projection(cursor, mode: :authoring)
    rescue ArgumentError, KeyError => e
      EditAffordances::Projection.new(
        rows: [],
        diagnostics: [
          EditAffordances::Projection::Diagnostic.new(
            severity: "error",
            message: e.message,
            cell_data: nil
          )
        ]
      )
    end

    def current_main_screen
      Array(@draft.body["screens"]).find { |screen| screen.is_a?(Hash) && screen["id"] == "main" }
    end

    def main_rows_for(body)
      Array(ensure_main_screen(body)["rows"])
    end

    def row_index_param
      Integer(params.require(:row_index), 10)
    end

    def cell_index_param
      Integer(params.require(:cell_index), 10)
    end

    def row_at!(index, rows: @rows)
      return rows[index] if index >= 0 && index < rows.length && rows[index].is_a?(Array)

      raise ActiveRecord::RecordNotFound, "row not found"
    end

    def cell_at!(row, index)
      return row[index] if index >= 0 && index < row.length && row[index].is_a?(Hash)

      raise ActiveRecord::RecordNotFound, "field not found"
    end

    def target_row_index(row_index, direction)
      case direction
      when "up"
        row_index - 1
      when "down"
        row_index + 1
      else
        row_index
      end
    end

    def target_cell_index(cell_index, direction)
      case direction
      when "left"
        cell_index - 1
      when "right"
        cell_index + 1
      else
        cell_index
      end
    end

    def width_class_for(width)
      case width
      when "narrow"
        "mx-auto w-full max-w-3xl"
      when "medium"
        "mx-auto w-full max-w-5xl"
      when "full"
        "w-full"
      else
        "mx-auto w-full max-w-[2560px]"
      end
    end

    def projection_affordance
      body = @draft.body
      @projection_affordance ||= EditAffordance.new(
        schema_wrapper: @schema_wrapper,
        edit_document: @draft.document
      ).tap do |affordance|
        affordance.define_singleton_method(:body) { body }
      end
    end

    def seeded_example_body
      Documents::SeedValue.for(@schema_wrapper.body)
    end

    def deep_dup_json(value)
      Marshal.load(Marshal.dump(value))
    end

    class SchemaPreviewSource
      attr_reader :schema_document, :body

      def initialize(schema_document:, body:)
        @schema_document = schema_document
        @body = body
      end

      def schema_document?
        false
      end
    end
  end
end
