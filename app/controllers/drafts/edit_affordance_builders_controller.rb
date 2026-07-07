# frozen_string_literal: true

module Drafts
  class EditAffordanceBuildersController < ApplicationController
    BUILDER_SPAN_RANGE = (1..12).freeze
    COMMIT_MODES = %w[review_screen immediate].freeze
    COLLECTION_CREATIONS = %w[new_screen inline_blank_form append_and_open].freeze
    DEFAULT_FIELD_SPAN = 3
    MESSAGE_MODES = %w[hidden inline_optional inline_required].freeze
    SCREEN_MODES = %w[page full_width].freeze
    WIDTHS = %w[narrow medium large full].freeze
    WIDGETS = %w[auto text textarea number checkbox select array base64_image reference].freeze
    COLLECTION_BINDING_OPTIONS = [
      [ "Property", "property" ],
      [ "Reference label", "reference_label" ],
      [ "Value label", "value_label" ],
      [ "None", "none" ]
    ].freeze

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
      builder_rows_for(body) << []
      @draft.update!(body: body)

      builder_update_response(notice: "Row added.")
    end

    def add_field
      result = body_with_added_field
      @draft.update!(body: result.fetch(:body))

      editor_update_response(
        notice: "Field added.",
        row_index: result.fetch(:row_index),
        cell_index: result.fetch(:cell_index),
        html_path: builder_path
      )
    rescue ArgumentError => e
      builder_error_response(e.message)
    end

    def add_navigation
      result = body_with_added_navigation
      @draft.update!(body: result.fetch(:body))

      editor_update_response(
        notice: "Navigation added.",
        row_index: result.fetch(:row_index),
        cell_index: result.fetch(:cell_index),
        html_path: builder_path
      )
    rescue ArgumentError => e
      builder_error_response(e.message)
    end

    def add_commit
      result = body_with_added_commit
      @draft.update!(body: result.fetch(:body))

      editor_update_response(
        notice: "Commit added.",
        row_index: result.fetch(:row_index),
        cell_index: result.fetch(:cell_index),
        html_path: builder_path
      )
    rescue ArgumentError => e
      builder_error_response(e.message)
    end

    def add_screen
      body = deep_dup_json(@draft.body)
      screen = screen_from_params(body)
      ensure_screens(body) << screen
      @draft.update!(body: body)

      builder_update_response(
        notice: "Screen added.",
        screen_id: screen.fetch("id"),
        html_path: builder_path(screen_id: screen.fetch("id"))
      )
    rescue ArgumentError => e
      builder_error_response(e.message)
    end

    def add_subform
      body = deep_dup_json(@draft.body)
      subform = subform_from_params(body)
      ensure_subforms(body) << subform
      @draft.update!(body: body)

      builder_update_response(notice: "Subform added.")
    rescue ArgumentError => e
      builder_error_response(e.message)
    end

    def add_index
      body = deep_dup_json(@draft.body)
      ensure_indexes(body) << root_index_from_params
      @draft.update!(body: body)

      builder_update_response(notice: "Index added.")
    rescue ArgumentError => e
      builder_error_response(e.message)
    end

    def apply_suggestion
      body = deep_dup_json(@draft.body)
      apply_builder_suggestion!(body, params.require(:suggestion_id))
      @draft.update!(body: body)

      builder_update_response(notice: "Suggestion applied.")
    rescue ArgumentError => e
      builder_error_response(e.message)
    end

    def update_screen
      body = deep_dup_json(@draft.body)
      screen = builder_screen_for(body)
      if params.key?(:title)
        title = params[:title].presence
        title ? screen["title"] = title : screen.delete("title")
      end
      body["start_screen"] = params[:start_screen].presence_in(screen_ids_for(body)) || "main"
      body["commit_mode"] = params[:default_commit_mode].presence_in(COMMIT_MODES) || "review_screen"
      root_ptr = params[:root_ptr].presence
      root_ptr ? screen["root_binding"] = { "kind" => "document_ptr", "ptr" => root_ptr } : screen.delete("root_binding")
      subform_id = params[:subform].presence
      if subform_id
        raise ArgumentError, "Select an existing subform." unless subform_ids_for(body).include?(subform_id)

        screen["subform"] = subform_id
        screen.delete("rows")
      else
        screen.delete("subform")
        screen["rows"] = Array(screen["rows"])
      end
      screen["width"] = params[:width].presence_in(WIDTHS) || "large"
      screen["mode"] = params[:screen_mode].presence_in(SCREEN_MODES) || "page"
      screen["default_span"] = normalized_span(params[:default_span])
      screen["commit_mode"] = params[:screen_commit_mode].presence_in(COMMIT_MODES) || "review_screen"
      screen["columns"] = 12
      update_active_subform_root!(screen, body) if params.key?(:subform_root_ptr)
      @draft.update!(body: body)

      builder_update_response(notice: "Screen layout updated.")
    rescue ArgumentError => e
      builder_error_response(e.message)
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
      rows = builder_rows_for(body)
      index = row_index_param
      row_at!(index, rows: rows)
      rows.delete_at(index)
      @draft.update!(body: body)

      builder_update_response(notice: "Row deleted.")
    end

    def delete_index
      body = deep_dup_json(@draft.body)
      indexes = ensure_indexes(body)
      index = index_index_param
      raise ActiveRecord::RecordNotFound, "index not found" unless index >= 0 && indexes[index].is_a?(Hash)

      indexes.delete_at(index)
      @draft.update!(body: body)

      builder_update_response(notice: "Index deleted.")
    end

    def move_row
      body = deep_dup_json(@draft.body)
      rows = builder_rows_for(body)
      row_index = row_index_param
      row_at!(row_index, rows: rows)
      target_index = target_row_index(row_index, params[:direction])
      unless target_index >= 0 && target_index < rows.length
        return builder_error_response("Row cannot be moved #{params[:direction]}.")
      end

      rows[row_index], rows[target_index] = rows[target_index], rows[row_index]
      @draft.update!(body: body)

      builder_update_response(notice: "Row moved.")
    end

    def delete_cell
      body = deep_dup_json(@draft.body)
      rows = builder_rows_for(body)
      row_index = row_index_param
      cell_index = cell_index_param
      row = row_at!(row_index, rows: rows)
      cell_at!(row, cell_index)
      row.delete_at(cell_index)
      @draft.update!(body: body)

      editor_update_response(notice: "Field deleted.", row_index: row_index)
    end

    def move_cell
      body = deep_dup_json(@draft.body)
      rows = builder_rows_for(body)
      row_index = row_index_param
      cell_index = cell_index_param
      row = row_at!(row_index, rows: rows)
      cell_at!(row, cell_index)
      target_index = target_cell_index(cell_index, params[:direction])
      unless target_index >= 0 && target_index < row.length
        return editor_error_response("Field cannot be moved #{params[:direction]}.", row_index: row_index)
      end

      row[cell_index], row[target_index] = row[target_index], row[cell_index]
      @draft.update!(body: body)

      editor_update_response(notice: "Field moved.", row_index: row_index)
    end

    def update_cell
      body = deep_dup_json(@draft.body)
      rows = builder_rows_for(body)
      row_index = row_index_param
      cell_index = cell_index_param
      row = row_at!(row_index, rows: rows)
      cell = cell_at!(row, cell_index)
      row[cell_index] = updated_cell_from_params(cell)
      @draft.update!(body: body)

      editor_update_response(notice: "Cell updated.", row_index: row_index, cell_index: cell_index)
    rescue ArgumentError => e
      redirect_to cell_path(params[:row_index], params[:cell_index]),
        alert: e.message
    end

    private

    def builder_update_response(notice:, screen_id: nil, html_path: nil)
      respond_to do |format|
        format.turbo_stream do
          flash.now[:notice] = notice
          load_context
          select_builder_screen_context!(screen_id) if screen_id
          render :builder_update
        end
        format.html do
          redirect_to html_path || builder_path,
            notice: notice
        end
      end
    end

    def builder_error_response(message)
      respond_to do |format|
        format.turbo_stream do
          flash.now[:alert] = message
          load_context
          render :builder_update, status: :unprocessable_entity
        end
        format.html do
          redirect_to builder_path,
            alert: message
        end
      end
    end

    def editor_update_response(notice:, row_index:, cell_index: nil, html_path: nil)
      respond_to do |format|
        format.turbo_stream do
          flash.now[:notice] = notice
          load_editor_context(row_index, cell_index)
          render :builder_update
        end
        format.html do
          redirect_to html_path || (cell_index.nil? ? row_path(row_index) : cell_path(row_index, cell_index)),
            notice: notice
        end
      end
    end

    def editor_error_response(message, row_index:, cell_index: nil)
      respond_to do |format|
        format.turbo_stream do
          flash.now[:alert] = message
          load_editor_context(row_index, cell_index)
          render :builder_update, status: :unprocessable_entity
        end
        format.html do
          redirect_to cell_index.nil? ? row_path(row_index) : cell_path(row_index, cell_index),
            alert: message
        end
      end
    end

    def load_editor_context(row_index, cell_index)
      load_context
      @row_index = row_index
      @row = row_at!(@row_index)
      if cell_index.nil?
        @tab = "row"
      else
        @tab = "cell"
        @cell_index = cell_index
        @cell = cell_at!(@row, @cell_index)
      end
    end

    def select_builder_screen_context!(screen_id)
      @selected_screen = Array(@draft.body["screens"]).find { |screen| screen.is_a?(Hash) && screen["id"] == screen_id } || @selected_screen
      @screen_id = @selected_screen&.fetch("id", nil) || "main"
      @active_subform = current_builder_subform
      @rows = current_builder_rows
      @builder_width_class = width_class_for(@selected_screen&.fetch("width", "large"))
    end

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
      @screen_ids = screen_ids
      @subform_ids = subform_ids
      @widget_options = WIDGETS
      @collection_binding_options = COLLECTION_BINDING_OPTIONS
      @collection_creation_options = COLLECTION_CREATIONS
      @screen_mode_options = SCREEN_MODES
      @selected_screen = current_builder_screen
      @screen_id = @selected_screen&.fetch("id", nil) || "main"
      @active_subform = current_builder_subform
      @rows = current_builder_rows
      @indexes = builder_index_entries
      @suggestions = builder_suggestions
      @screen_ids = screen_ids
      @builder_width_class = width_class_for(@selected_screen&.fetch("width", "large"))
    end

    def tab_param
      params[:tab].presence_in(%w[builder preview diagnostics raw]) || "builder"
    end

    def body_with_added_field
      body = deep_dup_json(@draft.body)
      row, row_index = target_row_with_index(body)
      row << field_cell_from_params
      {
        body: body,
        row_index: row_index,
        cell_index: row.length - 1
      }
    end

    def body_with_added_navigation
      body = deep_dup_json(@draft.body)
      row, row_index = target_row_with_index(body)
      row << navigation_cell_from_params
      {
        body: body,
        row_index: row_index,
        cell_index: row.length - 1
      }
    end

    def body_with_added_commit
      body = deep_dup_json(@draft.body)
      row, row_index = target_row_with_index(body)
      row << commit_cell_from_params
      {
        body: body,
        row_index: row_index,
        cell_index: row.length - 1
      }
    end

    def apply_builder_suggestion!(body, suggestion_id)
      case suggestion_id
      when "add_required_fields"
        add_entries_to_rows!(body, missing_required_entries)
      when "add_scalar_fields"
        add_entries_to_rows!(body, missing_scalar_entries)
      when "add_commit"
        append_row(builder_rows_for(body)) << default_commit_cell
      when "promote_long_text"
        promote_long_text_fields!(body)
      when "choice_room_layout"
        apply_choice_room_layout!(body)
      else
        if suggestion_id.start_with?("add_collection:")
          ptr = suggestion_id.delete_prefix("add_collection:")
          entry = @field_entries.find { |candidate| candidate.ptr == ptr && candidate.array? }
          raise ArgumentError, "Select an existing array field." unless entry

          append_row(builder_rows_for(body)) << collection_cell_for(entry)
        else
          raise ArgumentError, "Unknown suggestion."
        end
      end
    end

    def ensure_main_screen(body)
      body["version"] ||= 1
      body["start_screen"] ||= "main"
      body["commit_mode"] ||= "review_screen"
      ensure_subforms(body)
      screens = ensure_screens(body)
      main_screen = screens.find { |screen| screen.is_a?(Hash) && screen["id"] == "main" }
      return main_screen.tap { |screen| screen["rows"] = Array(screen["rows"]) } if main_screen

      screens << {
        "id" => "main",
        "title" => "Main",
        "columns" => 12,
        "default_span" => DEFAULT_FIELD_SPAN,
        "width" => "large",
        "rows" => []
      }
      screens.last
    end

    def ensure_screens(body)
      body["screens"] = Array(body["screens"])
    end

    def ensure_subforms(body)
      body["subforms"] = Array(body["subforms"])
    end

    def ensure_indexes(body)
      body["indexes"] = Array(body["indexes"])
    end

    def field_cell_from_params
      ptr = params.require(:ptr)
      widget = params[:widget].presence_in(WIDGETS) || "auto"
      field_entry = @field_entries.find { |entry| entry.ptr == ptr }
      cell = {
        "binding" => {
          "kind" => "document_ptr",
          "ptr" => ptr
        },
        "widget" => widget,
        "label" => ActiveModel::Type::Boolean.new.cast(params[:label]) == true
      }
      cell["span"] = normalized_span(params[:span])
      cell["help"] = params[:help] if params[:help].present?
      cell["placeholder"] = params[:placeholder] if params[:placeholder].present?
      display = display_config_from_params
      cell["display"] = display if display.present?
      cell["collection"] = collection_config_from_params if field_entry&.array?
      cell["reference"] = reference_config_from_params if widget == "reference"
      cell
    end

    def field_cell_for(entry, span: nil, widget: nil)
      cell = {
        "binding" => {
          "kind" => "document_ptr",
          "ptr" => entry.ptr
        },
        "widget" => widget || suggested_widget_for(entry),
        "label" => true,
        "span" => span || suggested_span_for(entry)
      }
      cell["collection"] = EditAffordances::Collection.default if entry.array?
      cell
    end

    def collection_cell_for(entry)
      field_cell_for(entry, span: 12, widget: "array").merge(
        "collection" => EditAffordances::Collection.default_config.merge(
          "presentation" => "cards",
          "creation" => "inline_blank_form",
          "delete" => "enabled",
          "reorder" => "enabled",
          "item_title" => item_title_binding_for(entry),
          "item_subtitle" => {
            "kind" => "value_label"
          }
        )
      ).tap do |cell|
        item_rows = item_rows_for_array_entry(entry)
        cell["item_rows"] = item_rows if item_rows.present?
      end
    end

    def navigation_cell_from_params
      target_screen = target_screen_param
      {
        "kind" => "navigation",
        "target_screen" => target_screen,
        "label" => params[:navigation_label].presence || target_screen.titleize,
        "span" => normalized_span(params[:navigation_span] || params[:span])
      }
    end

    def commit_cell_from_params
      {
        "kind" => "commit",
        "span" => normalized_span(params[:commit_span] || params[:span]),
        "message_mode" => params[:message_mode].presence_in(MESSAGE_MODES) || "inline_optional",
        "commit_mode" => params[:commit_mode].presence_in(COMMIT_MODES) || "review_screen"
      }
    end

    def updated_cell_from_params(cell)
      if field_cell?(cell)
        field_cell_from_params
      elsif navigation_cell?(cell)
        navigation_cell_from_params
      elsif commit_cell?(cell)
        commit_cell_from_params
      else
        raise ArgumentError, "Cell type is not supported by the structured editor."
      end
    end

    def target_row(body)
      target_row_with_index(body).first
    end

    def target_row_with_index(body)
      rows = builder_rows_for(body)
      raise ArgumentError, "Add a row before adding fields." if rows.empty?

      selected_index = params[:row_index].presence || (rows.length - 1).to_s
      index = begin
        Integer(selected_index, 10)
      rescue ArgumentError
        raise ArgumentError, "Select an existing row before adding a field."
      end
      return [ rows[index], index ] if index >= 0 && index < rows.length

      raise ArgumentError, "Select an existing row before adding a field."
    end

    def screen_from_params(body)
      ensure_main_screen(body)
      id = normalized_identifier(params[:new_screen_id], label: "Screen id")
      raise ArgumentError, "Screen id already exists." if screen_ids_for(body).include?(id)

      screen = {
        "id" => id,
        "title" => params[:new_screen_title].presence || id.titleize,
        "columns" => 12,
        "default_span" => normalized_span(params[:new_screen_default_span]),
        "mode" => params[:new_screen_mode].presence_in(SCREEN_MODES) || "page",
        "width" => params[:new_screen_width].presence_in(WIDTHS) || "large",
        "commit_mode" => params[:new_screen_commit_mode].presence_in(COMMIT_MODES) || "review_screen"
      }
      root_ptr = params[:new_screen_root_ptr].presence
      screen["root_binding"] = { "kind" => "document_ptr", "ptr" => root_ptr } if root_ptr
      subform_id = params[:new_screen_subform].presence
      if subform_id
        raise ArgumentError, "Select an existing subform." unless subform_ids_for(body).include?(subform_id)

        screen["subform"] = subform_id
      else
        screen["rows"] = []
      end
      screen
    end

    def subform_from_params(body)
      ensure_main_screen(body)
      id = normalized_identifier(params[:new_subform_id], label: "Subform id")
      raise ArgumentError, "Subform id already exists." if subform_ids_for(body).include?(id)

      {
        "id" => id,
        "rows" => []
      }.tap do |subform|
        root_ptr = params[:new_subform_root_ptr].presence
        subform["root_binding"] = { "kind" => "document_ptr", "ptr" => root_ptr } if root_ptr
      end
    end

    def root_index_from_params
      value_item_ptr = params[:index_value_item_ptr].to_s.strip
      value_root_ptr = params[:index_value_root_ptr].to_s.strip
      raise ArgumentError, "Index value pointer is required." if value_item_ptr.blank? && value_root_ptr.blank?

      value_expression = value_item_ptr.present? ? { "ptr" => value_item_ptr } : { "root_ptr" => value_root_ptr }
      value_strip_prefix = params[:index_value_strip_prefix].to_s
      value_expression["transform"] = { "strip_prefix" => value_strip_prefix } if value_strip_prefix.present?

      {
        "index_type" => normalized_identifier(params[:index_type], label: "Index type"),
        "value" => value_expression
      }.tap do |definition|
        source_ptr = params[:index_source_ptr].to_s.strip
        definition["source"] = { "ptr" => source_ptr, "each" => true } if source_ptr.present?
        key_item_ptr = params[:index_key_item_ptr].to_s.strip
        key_root_ptr = params[:index_key_root_ptr].to_s.strip
        key_literal = params[:index_key_literal].to_s.strip
        if key_item_ptr.present?
          definition["key"] = { "ptr" => key_item_ptr }
        elsif key_root_ptr.present?
          definition["key"] = { "root_ptr" => key_root_ptr }
        elsif key_literal.present?
          definition["key"] = { "literal" => key_literal }
        end
        label_ptr = params[:index_label_root_ptr].to_s.strip
        definition["label"] = { "root_ptr" => label_ptr } if label_ptr.present?
        metadata_key = params[:index_metadata_key].to_s.strip
        metadata_item_ptr = params[:index_metadata_item_ptr].to_s.strip
        metadata_ptr = params[:index_metadata_root_ptr].to_s.strip
        if metadata_key.present? && (metadata_item_ptr.present? || metadata_ptr.present?)
          metadata_expression = metadata_item_ptr.present? ? { "ptr" => metadata_item_ptr } : { "root_ptr" => metadata_ptr }
          metadata_strip_prefix = params[:index_metadata_strip_prefix].to_s
          metadata_expression["transform"] = { "strip_prefix" => metadata_strip_prefix } if metadata_strip_prefix.present?
          definition["metadata"] = {
            metadata_key => metadata_expression
          }
        end
        condition_ptr = params[:index_condition_root_ptr].to_s.strip
        condition_equals = params[:index_condition_equals].to_s.strip
        condition_in = params[:index_condition_in].to_s.split(",").map(&:strip).reject(&:blank?)
        if condition_ptr.present? && (condition_equals.present? || condition_in.present?)
          definition["condition"] = {
            "value" => { "root_ptr" => condition_ptr }
          }
          condition_in.present? ? definition["condition"]["in"] = condition_in : definition["condition"]["equals"] = condition_equals
        end
      end
    end

    def update_active_subform_root!(screen, body)
      subform = subform_for_screen(screen, body: body)
      return unless subform

      root_ptr = params[:subform_root_ptr].presence
      root_ptr ? subform["root_binding"] = { "kind" => "document_ptr", "ptr" => root_ptr } : subform.delete("root_binding")
    end

    def normalized_identifier(value, label:)
      id = value.to_s.strip
      raise ArgumentError, "#{label} is required." if id.blank?
      return id if id.match?(/\A[a-z][a-z0-9_-]*\z/)

      raise ArgumentError, "#{label} must start with a lowercase letter and use lowercase letters, numbers, dashes, or underscores."
    end

    def append_row(rows)
      rows << []
      rows.last
    end

    def add_entries_to_rows!(body, entries)
      raise ArgumentError, "No matching schema fields remain to add." if entries.empty?

      rows = builder_rows_for(body)
      entries.each_slice(3) do |group|
        rows << group.map { |entry| field_cell_for(entry) }
      end
    end

    def missing_required_entries
      missing_scalar_entries.select(&:required?)
    end

    def missing_scalar_entries
      used_ptrs = used_field_ptrs(@draft.body)
      @field_entries.select(&:scalar?).reject { |entry| used_ptrs.include?(entry.ptr) }
    end

    def missing_array_entries
      used_ptrs = used_field_ptrs(@draft.body)
      @field_entries.select(&:array?).reject { |entry| used_ptrs.include?(entry.ptr) }
    end

    def used_field_ptrs(body)
      Array(body["screens"]).flat_map { |screen| Array(screen["rows"]).flatten }
        .concat(Array(body["subforms"]).flat_map { |subform| Array(subform["rows"]).flatten })
        .filter_map { |cell| cell.dig("binding", "ptr") if cell.is_a?(Hash) }
        .uniq
    end

    def existing_commit?(body)
      Array(body["screens"]).flat_map { |screen| Array(screen["rows"]).flatten }
        .concat(Array(body["subforms"]).flat_map { |subform| Array(subform["rows"]).flatten })
        .any? { |cell| cell.is_a?(Hash) && cell["kind"] == "commit" }
    end

    def builder_suggestions
      [].tap do |suggestions|
        suggestions << suggestion("add_required_fields", "Add required fields", "#{missing_required_entries.count} required field(s) not in this affordance.") if missing_required_entries.any?
        suggestions << suggestion("add_scalar_fields", "Add scalar fields", "#{missing_scalar_entries.count} scalar field(s) can be added from the schema.") if missing_scalar_entries.any?
        missing_array_entries.each do |entry|
          suggestions << suggestion("add_collection:#{entry.ptr}", "Add #{entry.label} collection", "Create a card collection editor for #{entry.ptr}.")
        end
        suggestions << suggestion("promote_long_text", "Make long text textareas", "Promote description, summary, notes, prompt, and body fields already in the layout.") if long_text_cells(@draft.body).any?
        suggestions << suggestion("choice_room_layout", "Build three-choice room layout", "Realize a HyperCard-style challenge room editor.") if choice_room_schema?
        suggestions << suggestion("add_commit", "Add commit action", "Add a publish action to the current screen.") unless existing_commit?(@draft.body)
      end
    end

    def suggestion(id, title, description)
      {
        id: id,
        title: title,
        description: description
      }
    end

    def promote_long_text_fields!(body)
      changed = false
      all_cells_for(body).each do |cell|
        next unless field_cell?(cell)
        next unless long_text_ptr?(cell.dig("binding", "ptr"))
        next if cell["widget"] == "textarea"

        cell["widget"] = "textarea"
        cell["span"] = 12 if cell["span"].to_i < 12
        changed = true
      end
      raise ArgumentError, "No realized long text fields are available to refine." unless changed
    end

    def long_text_cells(body)
      all_cells_for(body).select do |cell|
        field_cell?(cell) && long_text_ptr?(cell.dig("binding", "ptr")) && cell["widget"] != "textarea"
      end
    end

    def all_cells_for(body)
      Array(body["screens"]).flat_map { |screen| Array(screen["rows"]).flatten }
        .concat(Array(body["subforms"]).flat_map { |subform| Array(subform["rows"]).flatten })
        .select { |cell| cell.is_a?(Hash) }
    end

    def long_text_ptr?(ptr)
      name = ptr.to_s.split("/").last.to_s
      %w[body description notes prompt summary terminal_text bio].include?(name)
    end

    def choice_room_schema?
      ptrs = @field_entries.map(&:ptr)
      %w[/name /room_type /prompt /choices].all? { |ptr| ptrs.include?(ptr) }
    end

    def apply_choice_room_layout!(body)
      screen = builder_screen_for(body)
      screen.delete("subform")
      screen["rows"] = [
        [ field_cell_for(entry_for_ptr!("/name"), span: 5), field_cell_for(entry_for_ptr!("/room_type"), span: 3), optional_field_cell("/stage", span: 4) ].compact,
        [ field_cell_for(entry_for_ptr!("/prompt"), span: 12, widget: "textarea") ],
        [ optional_field_cell("/terminal_text", span: 12, widget: "textarea") ].compact,
        [ collection_cell_for(entry_for_ptr!("/choices")) ],
        [ default_commit_cell ]
      ].reject(&:empty?)
    end

    def optional_field_cell(ptr, span:, widget: nil)
      entry = @field_entries.find { |candidate| candidate.ptr == ptr }
      field_cell_for(entry, span: span, widget: widget) if entry
    end

    def entry_for_ptr!(ptr)
      @field_entries.find { |entry| entry.ptr == ptr } || raise(ArgumentError, "Schema field #{ptr} is not available.")
    end

    def default_commit_cell
      {
        "kind" => "commit",
        "span" => 12,
        "commit_mode" => "review_screen",
        "message_mode" => "inline_optional"
      }
    end

    def suggested_widget_for(entry)
      return "textarea" if long_text_ptr?(entry.ptr)
      return "array" if entry.array?

      entry.widget.presence || "auto"
    end

    def suggested_span_for(entry)
      return 12 if entry.array? || suggested_widget_for(entry) == "textarea"

      entry.required? ? 6 : DEFAULT_FIELD_SPAN
    end

    def item_title_binding_for(entry)
      item_properties = entry.cursor.schema_node.dig("items", "properties")
      if item_properties.is_a?(Hash)
        preferred = %w[label name title].find { |name| item_properties.key?(name) }
        return { "kind" => "property", "name" => preferred } if preferred
      end

      { "kind" => "value_label" }
    end

    def item_rows_for_array_entry(entry)
      item_properties = entry.cursor.schema_node.dig("items", "properties")
      return [] unless item_properties.is_a?(Hash)

      item_properties.keys.each_slice(3).map do |property_names|
        property_names.map do |property_name|
          ptr = "/#{property_name}"
          widget = long_text_ptr?(ptr) ? "textarea" : "auto"
          cell = {
            "binding" => {
              "kind" => "document_ptr",
              "ptr" => ptr
            },
            "widget" => widget,
            "span" => widget == "textarea" ? 12 : 4
          }
          if @schema_wrapper.key == "mud-choice-room" && property_name == "target_room_key"
            cell["widget"] = "reference"
            cell["reference"] = {
              "schema_key" => "mud-choice-room",
              "index_type" => "identity",
              "index_key" => "document_key",
              "placeholder" => "Select next room"
            }
            cell["span"] = 4
          end
          cell
        end
      end
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
      config["item_screen"] = target_screen_param(param_name: :collection_item_screen, allow_blank: true) if params[:collection_item_screen].present?
      config
    end

    def reference_config_from_params
      {
        "schema_key" => params[:reference_schema_key].to_s,
        "index_type" => params[:reference_index_type].presence || "identity",
        "index_key" => params[:reference_index_key].presence || "document_key"
      }.tap do |config|
        config["schema_key_from"] = params[:reference_schema_key_from] if params[:reference_schema_key_from].present?
        config["placeholder"] = params[:reference_placeholder] if params[:reference_placeholder].present?
      end
    end

    def display_config_from_params
      {}.tap do |display|
        display["compact"] = true if ActiveModel::Type::Boolean.new.cast(params[:display_compact]) == true
        display["readonly"] = true if ActiveModel::Type::Boolean.new.cast(params[:display_readonly]) == true
      end
    end

    def collection_binding_from_params(prefix, default:)
      kind = params["#{prefix}_kind"].presence
      return default unless kind
      return { "kind" => "none" } if kind == "none"
      return { "kind" => "value_label" } if kind == "value_label"
      return reference_label_binding_from_params(prefix) if kind == "reference_label"

      {
        "kind" => "property",
        "name" => params["#{prefix}_name"].presence || default["name"].presence || "name"
      }
    end

    def reference_label_binding_from_params(prefix)
      {
        "kind" => "reference_label",
        "key_property" => params["#{prefix}_key_property"].presence || "key",
        "index_type" => params["#{prefix}_index_type"].presence || "identity",
        "index_key" => params["#{prefix}_index_key"].presence || "document_key"
      }.tap do |binding|
        schema_key = params["#{prefix}_schema_key"].presence
        schema_key_property = params["#{prefix}_schema_key_property"].presence
        if schema_key.present?
          binding["schema_key"] = schema_key
        else
          binding["schema_key_property"] = schema_key_property || "kind"
        end
      end
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

    def current_builder_screen
      ensure_main_screen(@draft.body)
      screens = Array(@draft.body["screens"]).select { |screen| screen.is_a?(Hash) }
      requested_id = params[:screen_id].presence || "main"
      screens.find { |screen| screen["id"] == requested_id } || screens.find { |screen| screen["id"] == "main" } || screens.first
    end

    def current_builder_subform
      subform_for_screen(@selected_screen, body: @draft.body)
    end

    def current_builder_rows
      target = @active_subform || @selected_screen
      return [] unless target

      target["rows"] = Array(target["rows"])
    end

    def builder_index_entries
      Array(@draft.body["indexes"]).each_with_index.filter_map do |definition, index|
        { index: index, definition: definition } if definition.is_a?(Hash)
      end
    end

    def screen_ids
      screen_ids_for(@draft.body)
    end

    def subform_ids
      subform_ids_for(@draft.body)
    end

    def screen_ids_for(body)
      Array(body["screens"]).filter_map do |screen|
        screen["id"] if screen.is_a?(Hash) && screen["id"].is_a?(String) && screen["id"].present?
      end
    end

    def subform_ids_for(body)
      Array(body["subforms"]).filter_map do |subform|
        subform["id"] if subform.is_a?(Hash) && subform["id"].is_a?(String) && subform["id"].present?
      end
    end

    def builder_screen_for(body)
      ensure_main_screen(body)
      screens = Array(body["screens"]).select { |screen| screen.is_a?(Hash) }
      requested_id = params[:screen_id].presence || @screen_id.presence || "main"
      screens.find { |screen| screen["id"] == requested_id } || screens.find { |screen| screen["id"] == "main" } || screens.first
    end

    def builder_rows_for(body)
      screen = builder_screen_for(body)
      target = subform_for_screen(screen, body: body) || screen
      target["rows"] = Array(target["rows"])
    end

    def subform_for_screen(screen, body:)
      return nil unless screen.is_a?(Hash) && screen["subform"].present?

      Array(body["subforms"]).find { |subform| subform.is_a?(Hash) && subform["id"] == screen["subform"] }
    end

    def row_index_param
      Integer(params.require(:row_index), 10)
    end

    def cell_index_param
      Integer(params.require(:cell_index), 10)
    end

    def index_index_param
      Integer(params.require(:index_index), 10)
    end

    def row_at!(index, rows: @rows)
      return rows[index] if index >= 0 && index < rows.length && rows[index].is_a?(Array)

      raise ActiveRecord::RecordNotFound, "row not found"
    end

    def cell_at!(row, index)
      return row[index] if index >= 0 && index < row.length && row[index].is_a?(Hash)

      raise ActiveRecord::RecordNotFound, "field not found"
    end

    def target_screen_param(param_name: :target_screen, allow_blank: false)
      value = params[param_name].presence
      return nil if value.blank? && allow_blank
      raise ArgumentError, "Select an existing screen." if value.blank?
      return value if screen_ids.include?(value)

      raise ArgumentError, "Select an existing screen."
    end

    def field_cell?(cell)
      cell.is_a?(Hash) && cell.key?("binding")
    end

    def navigation_cell?(cell)
      cell.is_a?(Hash) && cell["kind"] == "navigation"
    end

    def commit_cell?(cell)
      cell.is_a?(Hash) && cell["kind"] == "commit"
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

    def builder_path(tab: "builder", screen_id: @screen_id)
      options = { tab: tab }
      options[:screen_id] = screen_id if screen_id.present? && screen_id != "main"
      draft_edit_affordance_builder_path(@draft, options)
    end

    def row_path(row_index, screen_id: @screen_id)
      options = { row_index: row_index }
      options[:screen_id] = screen_id if screen_id.present? && screen_id != "main"
      row_draft_edit_affordance_builder_path(@draft, options)
    end

    def cell_path(row_index, cell_index, screen_id: @screen_id)
      options = { row_index: row_index, cell_index: cell_index }
      options[:screen_id] = screen_id if screen_id.present? && screen_id != "main"
      cell_draft_edit_affordance_builder_path(@draft, options)
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
