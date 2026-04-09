# frozen_string_literal: true

require "pathname"

ROOT = Pathname.new(__dir__).join("../..").expand_path

TARGETS = [
  ROOT.join("app/components/ui"),
  ROOT.join("app/components/navigation"),
  ROOT.join("app/components/editors"),
  ROOT.join("app/lib/documents"),
  ROOT.join("app/lib/schemas"),
  ROOT.join("app/lib/editors"),
  ROOT.join("app/lib/json_ptr"),
  ROOT.join("app/models/documents"),
  ROOT.join("app/presenters/documents")
].freeze

def camelize(str)
  str.split("_").map(&:capitalize).join
end

def namespace_for(path)
  relative = path.relative_path_from(ROOT).to_s

  case relative
  when %r{\Aapp/components/ui/}
    [ "Ui" ]
  when %r{\Aapp/components/navigation/nav_menu/}
    [ "Navigation", "NavMenu" ]
  when %r{\Aapp/components/navigation/}
    [ "Navigation" ]
  when %r{\Aapp/components/editors/}
    [ "Editors" ]
  when %r{\Aapp/lib/documents/}
    [ "Documents" ]
  when %r{\Aapp/lib/schemas/}
    [ "Schemas" ]
  when %r{\Aapp/lib/editors/}
    [ "Editors" ]
  when %r{\Aapp/lib/json_ptr/}
    [ "JsonPtr" ]
  when %r{\Aapp/models/documents/}
    [ "Documents" ]
  when %r{\Aapp/presenters/documents/}
    [ "Documents" ]
  else
    []
  end
end

def constant_name_for(path)
  camelize(path.basename(".rb").to_s)
end

def normalize_file(path)
  source = path.read

  return if source.include?("# namespace: keep")
  return if source.include?("module #{namespace_for(path).first}") && source.include?("class #{constant_name_for(path)}")

  class_match = source.match(/^class\s+([A-Za-z0-9_:]+)/)
  module_match = source.match(/^module\s+([A-Za-z0-9_:]+)/)

  namespaces = namespace_for(path)
  constant = constant_name_for(path)

  inner =
    if class_match
      source.sub(/^class\s+([A-Za-z0-9_:]+)/, "class #{constant}")
    elsif module_match
      source.sub(/^module\s+([A-Za-z0-9_:]+)/, "module #{constant}")
    else
      source
    end

  wrapped = inner
  namespaces.reverse_each do |mod|
    wrapped = <<~RUBY.chomp + "\n" + indent(wrapped)
      module #{mod}
      RUBY
    wrapped << "end\n"
  end

  path.write(wrapped)
  puts "normalized #{path.relative_path_from(ROOT)}"
end

def indent(text)
  text.lines.map { |line| line.strip.empty? ? line : "  #{line}" }.join
end

TARGETS.each do |dir|
  Dir.glob(dir.join("**/*.rb")).sort.each do |file|
    normalize_file(Pathname.new(file))
  end
end
