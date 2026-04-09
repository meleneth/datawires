# frozen_string_literal: true

require "pathname"

ROOT = Pathname.new(__dir__).join("../..").expand_path

REPLACEMENTS = {
  "ButtonComponent" => "Ui::ButtonComponent",
  "CardComponent" => "Ui::CardComponent",
  "FancyTextInputComponent" => "Ui::FancyTextInputComponent",
  "FieldComponent" => "Ui::FieldComponent",
  "PageHeaderComponent" => "Ui::PageHeaderComponent",
  "SplitOneFourOneComponent" => "Ui::SplitOneFourOneComponent",
  "TextFieldComponent" => "Ui::TextFieldComponent",

  "DocumentNavRibbonComponent" => "Navigation::DocumentNavRibbonComponent",
  "SchemaNavRibbonComponent" => "Navigation::SchemaNavRibbonComponent",
  "NavMenuComponent" => "Navigation::NavMenuComponent",
  "NavMenu::ItemComponent" => "Navigation::NavMenu::ItemComponent",

  "DocumentScalarFieldComponent" => "Editors::DocumentScalarFieldComponent",

  "DocumentEditorCommitCell" => "Editors::CommitCell",
  "DocumentEditorFieldCell" => "Editors::FieldCell",
  "DocumentEditorRow" => "Editors::Row",

  "DocumentProjectionRow" => "Documents::ProjectionRow",
  "DocumentProjection" => "Documents::Projection",
  "DocumentPath" => "Documents::Path",
  "DocumentSeedValue" => "Documents::SeedValue",

  "SchemaNav" => "Schemas::Nav",
  "SchemaPath" => "Schemas::Path",
  "SchemaResolver" => "Schemas::Resolver",
  "SchemaRibbonMenuItem" => "Schemas::RibbonMenuItem",
  "SchemaRibbonSegment" => "Schemas::RibbonSegment",

  "JsonPtrNav" => "JsonPtr::Nav",

  "DocumentScalarFieldRow" => "Documents::ScalarFieldRow",
  "DocumentSchemaFieldRow" => "Documents::SchemaFieldRow"
}.freeze

TARGET_DIRS = %w[
  app
  config
  db
  spec
].freeze

EXTENSIONS = %w[
  .rb
  .haml
  .erb
  .rake
].freeze

def candidate_file?(path)
  EXTENSIONS.include?(path.extname)
end

TARGET_DIRS.each do |dir|
  Dir.glob(ROOT.join(dir, "**/*")).sort.each do |file|
    path = Pathname.new(file)
    next unless path.file?
    next unless candidate_file?(path)

    original = path.read
    updated = original.dup

    REPLACEMENTS.each do |from, to|
      updated.gsub!(from, to)
    end

    next if updated == original

    path.write(updated)
    puts "updated #{path.relative_path_from(ROOT)}"
  end
end
