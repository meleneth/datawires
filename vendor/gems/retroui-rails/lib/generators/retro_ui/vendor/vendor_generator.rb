# frozen_string_literal: true

require "rails/generators"

module RetroUI
  module Generators
    class VendorGenerator < ::Rails::Generators::Base
      desc "Copy RetroUI Rails components into the host application."

      class_option :force, type: :boolean, default: false, desc: "Overwrite existing vendored files."

      COMPONENT_FILES = %w[
        button_component.rb
        button_component.html.erb
        card_component.rb
        card_component.html.erb
        card_header_component.rb
        card_header_component.html.erb
        card_title_component.rb
        card_title_component.html.erb
        card_description_component.rb
        card_description_component.html.erb
        card_content_component.rb
        card_content_component.html.erb
        badge_component.rb
        badge_component.html.erb
        alert_component.rb
        alert_component.html.erb
        alert_title_component.rb
        alert_title_component.html.erb
        alert_description_component.rb
        alert_description_component.html.erb
        input_component.rb
        input_component.html.erb
        textarea_component.rb
        textarea_component.html.erb
        label_component.rb
        label_component.html.erb
        checkbox_component.rb
        checkbox_component.html.erb
        radio_component.rb
        radio_component.html.erb
        select_component.rb
        select_component.html.erb
        separator_component.rb
        separator_component.html.erb
        skeleton_component.rb
        skeleton_component.html.erb
        progress_component.rb
        progress_component.html.erb
        table_component.rb
        table_component.html.erb
        table_header_component.rb
        table_header_component.html.erb
        table_body_component.rb
        table_body_component.html.erb
        table_footer_component.rb
        table_footer_component.html.erb
        table_row_component.rb
        table_row_component.html.erb
        table_head_component.rb
        table_head_component.html.erb
        table_cell_component.rb
        table_cell_component.html.erb
        table_caption_component.rb
        table_caption_component.html.erb
        avatar_component.rb
        avatar_component.html.erb
        avatar_image_component.rb
        avatar_image_component.html.erb
        avatar_fallback_component.rb
        avatar_fallback_component.html.erb
        aspect_ratio_component.rb
        aspect_ratio_component.html.erb
        breadcrumb_component.rb
        breadcrumb_component.html.erb
        breadcrumb_list_component.rb
        breadcrumb_list_component.html.erb
        breadcrumb_item_component.rb
        breadcrumb_item_component.html.erb
        breadcrumb_link_component.rb
        breadcrumb_link_component.html.erb
        breadcrumb_page_component.rb
        breadcrumb_page_component.html.erb
        breadcrumb_separator_component.rb
        breadcrumb_separator_component.html.erb
        pagination_component.rb
        pagination_component.html.erb
        pagination_content_component.rb
        pagination_content_component.html.erb
        pagination_item_component.rb
        pagination_item_component.html.erb
        pagination_link_component.rb
        pagination_link_component.html.erb
        typography_component.rb
        code_component.rb
        code_component.html.erb
        kbd_component.rb
        kbd_component.html.erb
        switch_component.rb
        switch_component.html.erb
        toast_viewport_component.rb
        toast_viewport_component.html.erb
        toast_component.rb
        toast_component.html.erb
        toast_title_component.rb
        toast_title_component.html.erb
        toast_description_component.rb
        toast_description_component.html.erb
        toast_close_component.rb
        toast_close_component.html.erb
        accordion_component.rb
        accordion_component.html.erb
        accordion_item_component.rb
        accordion_item_component.html.erb
        accordion_trigger_component.rb
        accordion_trigger_component.html.erb
        accordion_content_component.rb
        accordion_content_component.html.erb
        tabs_component.rb
        tabs_component.html.erb
        tabs_list_component.rb
        tabs_list_component.html.erb
        tabs_trigger_component.rb
        tabs_trigger_component.html.erb
        tabs_content_component.rb
        tabs_content_component.html.erb
        dialog_component.rb
        dialog_component.html.erb
        dialog_trigger_component.rb
        dialog_trigger_component.html.erb
        dialog_content_component.rb
        dialog_content_component.html.erb
        dialog_close_component.rb
        dialog_close_component.html.erb
        dialog_header_component.rb
        dialog_header_component.html.erb
        dialog_title_component.rb
        dialog_title_component.html.erb
        dialog_description_component.rb
        dialog_description_component.html.erb
        dialog_footer_component.rb
        dialog_footer_component.html.erb
        dropdown_menu_component.rb
        dropdown_menu_component.html.erb
        dropdown_menu_trigger_component.rb
        dropdown_menu_trigger_component.html.erb
        dropdown_menu_content_component.rb
        dropdown_menu_content_component.html.erb
        dropdown_menu_item_component.rb
        dropdown_menu_item_component.html.erb
        popover_component.rb
        popover_component.html.erb
        popover_trigger_component.rb
        popover_trigger_component.html.erb
        popover_content_component.rb
        popover_content_component.html.erb
        tooltip_component.rb
        tooltip_component.html.erb
        tooltip_trigger_component.rb
        tooltip_trigger_component.html.erb
        tooltip_content_component.rb
        tooltip_content_component.html.erb
        chart_component.rb
        chart_component.html.erb
        area_chart_component.rb
        area_chart_component.html.erb
        bar_chart_component.rb
        bar_chart_component.html.erb
        line_chart_component.rb
        line_chart_component.html.erb
        pie_chart_component.rb
        pie_chart_component.html.erb
      ].freeze

      CONTROLLER_FILES = %w[
        accordion_controller.js
        chart_controller.js
        tabs_controller.js
        dialog_controller.js
        dropdown_menu_controller.js
        popover_controller.js
        tooltip_controller.js
        toast_controller.js
      ].freeze

      def copy_components
        COMPONENT_FILES.each do |filename|
          copy_with_namespace_rewrite(
            gem_root.join("app/components/retro_ui/rails/#{filename}"),
            destination_path.join("app/components/retro_ui/#{filename}")
          )
        end
      end

      def copy_theme
        copy_with_namespace_rewrite(
          gem_root.join("app/assets/stylesheets/retro_ui/rails/theme.css"),
          destination_path.join("app/assets/stylesheets/retro_ui/theme.css")
        )
      end

      def copy_controllers
        CONTROLLER_FILES.each do |filename|
          copy_with_namespace_rewrite(
            gem_root.join("app/javascript/retro_ui/rails/controllers/#{filename}"),
            destination_path.join("app/javascript/controllers/retro_ui/#{filename}")
          )
        end
      end

      def print_done
        say ""
        say "RetroUI components have been vendored into your app.", :green
        say "Future retroui-rails gem updates will not automatically alter these vendored copies."
      end

      private

      def copy_with_namespace_rewrite(source, destination)
        if destination.exist? && !options[:force]
          raise ::Rails::Generators::Error, "Refusing to overwrite #{relative_to_destination(destination)}. Re-run with --force to replace it."
        end

        empty_directory destination.dirname
        content = rewrite_content(source)
        create_file destination, content, force: options[:force]
        say "Copied #{relative_to_destination(destination)}"
      end

      def rewrite_content(source)
        content = source.read.gsub("RetroUI::Rails", "RetroUI")
        return content unless source.extname == ".rb"

        content = content.sub(/module RetroUI\n  module Rails\n    class ([^\n]+)\n/, "class RetroUI::\\1\n")
        content = content.sub(/\n    end\n  end\nend\n?\z/, "\nend\n")
        content = content.lines.map { |line| line.start_with?("      ") ? line[4..] : line }.join
        content = content.gsub(" < ChartComponent", " < RetroUI::ChartComponent")
        content = content.sub(/^  include RetroUI::ClassNames\n\n/, "")
        content.sub(/\nend\n\z/, "\n#{vendored_class_names_helper}\nend\n")
      end

      def vendored_class_names_helper
        <<~RUBY
            private

            # Small class-list helper copied with vendored components.
            # It does not implement Tailwind-aware conflict resolution.
            def class_names(*values)
              values.flatten.compact.reject { |value| value == false }.map(&:to_s).reject(&:empty?).join(" ")
            end
        RUBY
      end

      def gem_root
        Pathname.new(File.expand_path("../../../..", __dir__))
      end

      def destination_path
        Pathname.new(destination_root)
      end

      def relative_to_destination(path)
        path.relative_path_from(destination_path).to_s
      end
    end
  end
end
