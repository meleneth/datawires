# frozen_string_literal: true

module Drafts
  class EditAffordanceBuildersController < ApplicationController
    before_action :load_context

    def show
      @tab = tab_param
    end

    def add_field
      @draft.update!(body: body_with_added_field)

      redirect_to draft_edit_affordance_builder_path(@draft, tab: "builder"),
        notice: "Field added."
    end

    def update_raw
      @draft.update!(body: JSON.parse(params.require(:body_json)))

      redirect_to draft_edit_affordance_builder_path(@draft, tab: "raw"),
        notice: "Raw affordance JSON updated."
    rescue JSON::ParserError => e
      redirect_to draft_edit_affordance_builder_path(@draft, tab: "raw"),
        alert: "Invalid JSON: #{e.message}"
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
    end

    def tab_param
      params[:tab].presence_in(%w[builder preview diagnostics raw]) || "builder"
    end

    def body_with_added_field
      body = deep_dup_json(@draft.body)
      main_screen = ensure_main_screen(body)
      main_screen["rows"] << [ field_cell_from_params ]
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
        "default_span" => 4,
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
      cell["span"] = params[:span].to_i if params[:span].present?
      cell["help"] = params[:help] if params[:help].present?
      cell["collection"] = collection_config_from_params if widget == "array" || field_entry&.array?
      cell
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
