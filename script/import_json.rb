# script/import_json.rb
# frozen_string_literal: true

require "optparse"
require "net/http"
require "json"
require "set"
require "uri"
require "pathname"
require "time"
require "ostruct"

module Datawires
  module ImportJson
    class Error < StandardError; end

    class CLI
      DEFAULT_DOMAIN_NAME = "Datawires"

      def self.run(argv)
        new(argv).run
      end

      def initialize(argv)
        @argv = argv.dup
        @options = {
          domain_name: DEFAULT_DOMAIN_NAME,
          follow_refs: nil,
          dry_run: false
        }
      end

      def run
        parser.parse!(@argv)

        mode = @argv.shift
        source = @argv.shift

        unless %w[schema document].include?(mode)
          raise Error, "first argument must be 'schema' or 'document'"
        end

        raise Error, "source is required" if source.nil? || source.strip.empty?

        @options[:follow_refs] = (mode == "schema") if @options[:follow_refs].nil?

        result = Runner.new(
          mode:,
          source:,
          **@options
        ).call

        puts "Imported #{result.fetch(:documents).size} document(s):"
        result.fetch(:documents).each do |document|
          puts "  - #{document.key}"
        end

        true
      rescue OptionParser::ParseError, Error => e
        warn e.message
        warn
        warn parser
        exit 1
      end

      private

      def parser
        @parser ||= OptionParser.new do |opts|
          opts.banner = <<~TEXT
            Usage:
              bin/rails runner script/import_json.rb schema SOURCE [options]
              bin/rails runner script/import_json.rb document SOURCE [options]

            SOURCE may be:
              - https://...
              - http://...
              - file:///absolute/path.json
              - /absolute/path.json
              - ./relative/path.json
          TEXT

          opts.on("--domain NAME", "Domain name (default: #{@options[:domain_name]})") do |value|
            @options[:domain_name] = value
          end

          opts.on("--key KEY", "Override the local document key") do |value|
            @options[:key] = value
          end

          opts.on("--title TITLE", "Override the local document title") do |value|
            @options[:title] = value
          end

          opts.on("--canonical-url URL", "Canonical URI for the imported resource") do |value|
            @options[:canonical_url] = value
          end

          opts.on("--message TEXT", "Revision message override") do |value|
            @options[:message] = value
          end

          opts.on("--schema-key KEY", "Schema document key for document imports") do |value|
            @options[:schema_key] = value
          end

          opts.on("--schema-canonical-uri URI", "Schema canonical URI for document imports") do |value|
            @options[:schema_canonical_uri] = value
          end

          opts.on("--schema-source URL_OR_FILE", "Schema source to import or resolve for document imports") do |value|
            @options[:schema_source] = value
          end

          opts.on("--follow-refs", "Recursively import referenced schemas") do
            @options[:follow_refs] = true
          end

          opts.on("--no-follow-refs", "Do not recursively import referenced schemas") do
            @options[:follow_refs] = false
          end

          opts.on("--dry-run", "Do not persist anything") do
            @options[:dry_run] = true
          end

          opts.on("-h", "--help", "Show help") do
            puts opts
            exit 0
          end
        end
      end
    end

    class Runner
      def initialize(
        mode:,
        source:,
        domain_name:,
        key: nil,
        title: nil,
        canonical_url: nil,
        message: nil,
        schema_key: nil,
        schema_canonical_uri: nil,
        schema_source: nil,
        follow_refs:,
        dry_run: false
      )
        @mode = mode
        @source = Source.new(source)
        @domain_name = domain_name
        @key = key
        @title = title
        @canonical_url = canonical_url
        @message = message
        @schema_key = schema_key
        @schema_canonical_uri = schema_canonical_uri
        @schema_source = schema_source
        @follow_refs = follow_refs
        @dry_run = dry_run
      end

      def call
        domain = Domain.find_or_create_by!(name: @domain_name)

        if schema_mode?
          run_schema_import(domain:)
        else
          run_document_import(domain:)
        end
      end

      private

      def schema_mode?
        @mode == "schema"
      end

      def run_schema_import(domain:)
        graph = SchemaGraphImporter.new(
          root_source: @source,
          canonical_root_uri: @canonical_url,
          domain_name: @domain_name,
          follow_refs: @follow_refs
        ).call

        documents = if @dry_run
          graph.fetch(:nodes).map do |node|
            OpenStruct.new(key: node.fetch(:local_key))
          end
        else
          SchemaGraphPersistor.new(
            domain:,
            graph:,
            message: @message
          ).call
        end

        { documents: }
      end

      def run_document_import(domain:)
        source_payload = @source.read_json
        body = source_payload.fetch(:body)

        schema_document = resolve_schema_document(domain:, body:)
        local_key = @key || derive_document_key(source_payload:, body:)
        local_title = @title || body["title"] || File.basename(local_key)
        canonical_uri = @canonical_url || infer_document_canonical_uri(source_payload:, body:)
        canonical_uri = UriTools.defragment(canonical_uri) if canonical_uri

        if @dry_run
          document = OpenStruct.new(key: local_key)
          return { documents: [ document ] }
        end

        document = upsert_document_with_revision!(
          domain:,
          key: local_key,
          title: local_title,
          body:,
          schema_document:,
          message: @message || default_document_message(source_payload)
        )

        upsert_external_document!(
          document:,
          canonical_uri:,
          source_uri: source_payload.fetch(:source_uri),
          source_kind: source_payload.fetch(:source_kind)
        )

        { documents: [ document ] }
      end

      def resolve_schema_document(domain:, body:)
        return domain.documents.find_by!(key: @schema_key) if @schema_key

        if @schema_canonical_uri
          external = ExternalDocument.find_by!(
            canonical_uri: UriTools.defragment(@schema_canonical_uri)
          )
          return external.document
        end

        if @schema_source
          schema_result = self.class.new(
            mode: "schema",
            source: @schema_source,
            domain_name: @domain_name,
            canonical_url: nil,
            follow_refs: true,
            dry_run: false
          ).call

          return schema_result.fetch(:documents).first
        end

        declared_schema = body["$schema"]
        return nil if declared_schema.nil? || declared_schema.strip.empty?

        external = ExternalDocument.find_by(
          canonical_uri: UriTools.defragment(declared_schema)
        )
        external&.document
      end

      def infer_document_canonical_uri(source_payload:, body:)
        return @canonical_url if @canonical_url
        return body["$id"] if body.is_a?(Hash) && body["$id"].is_a?(String) && !body["$id"].empty?
        return source_payload.fetch(:source_uri) if source_payload.fetch(:source_kind) == "url"

        nil
      end

      def derive_document_key(source_payload:, body:)
        if body["$id"].is_a?(String) && !body["$id"].empty?
          return KeyMapper.local_key_for(body["$id"])
        end

        base =
          if source_payload.fetch(:source_kind) == "file"
            Pathname.new(source_payload.fetch(:source_path)).basename.sub_ext("").to_s
          else
            uri = URI.parse(source_payload.fetch(:source_uri))
            File.basename(uri.path.presence || "document.json", ".json")
          end

        "imports/documents/#{base}"
      end

      def default_document_message(source_payload)
        "Import document from #{source_payload.fetch(:source_uri)}"
      end

      def upsert_document_with_revision!(domain:, key:, title:, body:, schema_document:, message:)
        document = Document.find_or_initialize_by(domain:, key:)
        document.title = title
        document.schema_document = schema_document if schema_document
        document.save! if document.new_record? || document.changed?

        current_body = document.head_revision&.body
        return document if current_body == body

        revision = document.revisions.create!(
          body:,
          message:,
          parent_revision: document.head_revision
        )

        document.update!(head_revision: revision)
        document
      end

      def upsert_external_document!(document:, canonical_uri:, source_uri:, source_kind:)
        raise Error, "canonical URI is required for external documents" if canonical_uri.nil? || canonical_uri.empty?

        external = document.external_document || document.build_external_document
        external.canonical_uri = canonical_uri
        external.source_uri = source_uri
        external.source_kind = source_kind
        external.imported_at = Time.current
        external.save!
      end
    end

    class SchemaGraphImporter
      def initialize(root_source:, canonical_root_uri:, domain_name:, follow_refs:)
        @root_source = root_source
        @canonical_root_uri = canonical_root_uri
        @domain_name = domain_name
        @follow_refs = follow_refs
      end

      def call
        root_payload = @root_source.read_json
        root_body = root_payload.fetch(:body)
        root_canonical_uri = @canonical_root_uri || infer_canonical_uri(root_payload:, body: root_body)
        root_canonical_uri = UriTools.defragment(root_canonical_uri)

        raise Error, "schema imports require a canonical URI or $id or URL source" if blank?(root_canonical_uri)

        queue = [ Node.new(
          source_uri: root_payload.fetch(:source_uri),
          source_kind: root_payload.fetch(:source_kind),
          source_path: root_payload[:source_path],
          canonical_uri: root_canonical_uri,
          original_body: root_body
        ) ]

        seen = Set.new
        nodes_by_canonical_uri = {}

        until queue.empty?
          node = queue.shift
          next if seen.include?(node.canonical_uri)

          seen << node.canonical_uri
          nodes_by_canonical_uri[node.canonical_uri] = node

          next unless @follow_refs

          ReferenceScanner.remote_references(
            body: node.original_body,
            base_uri: node.canonical_uri
          ).each do |ref_uri|
            next if seen.include?(ref_uri)

            ref_source = Source.new(ref_uri)
            payload = ref_source.read_json

            queue << Node.new(
              source_uri: payload.fetch(:source_uri),
              source_kind: payload.fetch(:source_kind),
              source_path: payload[:source_path],
              canonical_uri: UriTools.defragment(ref_uri),
              original_body: payload.fetch(:body)
            )
          end
        end

        local_uri_map = nodes_by_canonical_uri.keys.each_with_object({}) do |canonical_uri, memo|
          local_key = KeyMapper.local_key_for(canonical_uri)
          memo[canonical_uri] = LocalUri.build(domain_name: @domain_name, key: local_key)
        end

        nodes = nodes_by_canonical_uri.values.map do |node|
          local_key = KeyMapper.local_key_for(node.canonical_uri)
          local_uri = local_uri_map.fetch(node.canonical_uri)
          rewritten_body = Retargeter.rewrite(
            body: node.original_body,
            current_canonical_uri: node.canonical_uri,
            current_local_uri: local_uri,
            local_uri_map:
          )

          {
            canonical_uri: node.canonical_uri,
            local_key:,
            local_uri:,
            title: rewritten_body["title"] || File.basename(local_key),
            source_uri: node.source_uri,
            source_kind: node.source_kind,
            source_path: node.source_path,
            body: rewritten_body
          }
        end

        {
          root_canonical_uri:,
          root_local_key: KeyMapper.local_key_for(root_canonical_uri),
          nodes:
        }
      end

      private

      Node = Struct.new(
        :source_uri,
        :source_kind,
        :source_path,
        :canonical_uri,
        :original_body,
        keyword_init: true
      )

      def infer_canonical_uri(root_payload:, body:)
        return @canonical_root_uri if @canonical_root_uri
        return body["$id"] if body["$id"].is_a?(String) && !body["$id"].empty?
        return root_payload.fetch(:source_uri) if root_payload.fetch(:source_kind) == "url"

        nil
      end

      def blank?(value)
        value.nil? || value.respond_to?(:empty?) && value.empty?
      end
    end

    class SchemaGraphPersistor
      def initialize(domain:, graph:, message:)
        @domain = domain
        @graph = graph
        @message = message
      end

      def call
        root_local_key = @graph.fetch(:root_local_key)
        nodes = @graph.fetch(:nodes)

        ActiveRecord::Base.transaction do
          documents_by_key = nodes.each_with_object({}) do |node, memo|
            document = Document.find_or_initialize_by(domain: @domain, key: node.fetch(:local_key))
            document.title = node.fetch(:title)
            document.save! if document.new_record? || document.changed?
            memo[document.key] = document
          end

          root_document = documents_by_key.fetch(root_local_key)

          nodes.each do |node|
            document = documents_by_key.fetch(node.fetch(:local_key))

            current_body = document.head_revision&.body
            if current_body != node.fetch(:body)
              revision = document.revisions.create!(
                body: node.fetch(:body),
                message: @message || "Import schema from #{node.fetch(:canonical_uri)}",
                parent_revision: document.head_revision
              )
              document.head_revision = revision
            end

            document.schema_document = root_document
            document.save!

            external = document.external_document || document.build_external_document
            external.canonical_uri = node.fetch(:canonical_uri)
            external.source_uri = node.fetch(:source_uri)
            external.source_kind = node.fetch(:source_kind)
            external.imported_at = Time.current
            external.save!
          end

          nodes.map { |node| documents_by_key.fetch(node.fetch(:local_key)) }
        end
      end
    end

    class Source
      def initialize(raw)
        @raw = raw
      end

      def read_json
        if url?
          body_text = http_get(@raw)
          {
            body: parse_json(body_text),
            source_uri: @raw,
            source_kind: "url"
          }
        elsif file_uri?
          path = URI.parse(@raw).path
          {
            body: parse_json(File.read(path)),
            source_uri: "file://#{path}",
            source_kind: "file",
            source_path: path
          }
        else
          path = Pathname.new(@raw).expand_path.to_s
          {
            body: parse_json(File.read(path)),
            source_uri: "file://#{path}",
            source_kind: "file",
            source_path: path
          }
        end
      end

      private

      def url?
        uri = URI.parse(@raw)
        uri.is_a?(URI::HTTP)
      rescue URI::InvalidURIError
        false
      end

      def file_uri?
        uri = URI.parse(@raw)
        uri.scheme == "file"
      rescue URI::InvalidURIError
        false
      end

      def http_get(url)
        uri = URI.parse(url)
        response = Net::HTTP.get_response(uri)

        unless response.is_a?(Net::HTTPSuccess)
          raise Error, "failed to fetch #{url}: #{response.code} #{response.message}"
        end

        response.body
      end

      def parse_json(text)
        JSON.parse(text)
      rescue JSON::ParserError => e
        raise Error, "invalid JSON: #{e.message}"
      end
    end

    module ReferenceScanner
      REFERENCE_KEYS = %w[$ref $dynamicRef].freeze
      module_function

      def remote_references(body:, base_uri:)
        refs = Set.new

        walk(body) do |node|
          next unless node.is_a?(Hash)

          REFERENCE_KEYS.each do |key|
            raw_ref = node[key]
            next unless raw_ref.is_a?(String)
            next if raw_ref.start_with?("#")

            resolved = UriResolver.resolve(base_uri:, ref: raw_ref)
            document_uri = UriTools.defragment(resolved)

            refs << document_uri if http_uri?(document_uri)
          end
        end

        refs.to_a
      end

      def walk(node, &block)
        yield node

        case node
        when Hash
          node.each_value { |value| walk(value, &block) }
        when Array
          node.each { |value| walk(value, &block) }
        end
      end

      def http_uri?(value)
        uri = URI.parse(value)
        uri.is_a?(URI::HTTP)
      rescue URI::InvalidURIError
        false
      end
    end

    module Retargeter
      REFERENCE_KEYS = %w[$ref $dynamicRef $schema].freeze
      module_function

      def rewrite(body:, current_canonical_uri:, current_local_uri:, local_uri_map:)
        deep_copy_and_rewrite(body) do |key, value|
          next value unless value.is_a?(String)

          case key
          when "$id"
            current_local_uri
          when *REFERENCE_KEYS
            rewrite_reference(
              current_canonical_uri:,
              value:,
              local_uri_map:
            )
          else
            value
          end
        end
      end

      def deep_copy_and_rewrite(node, &block)
        case node
        when Hash
          node.each_with_object({}) do |(key, value), memo|
            memo[key] =
              if value.is_a?(Hash) || value.is_a?(Array)
                deep_copy_and_rewrite(value, &block)
              else
                block.call(key, value)
              end
          end
        when Array
          node.map do |value|
            if value.is_a?(Hash) || value.is_a?(Array)
              deep_copy_and_rewrite(value, &block)
            else
              value
            end
          end
        else
          node
        end
      end

      def rewrite_reference(current_canonical_uri:, value:, local_uri_map:)
        return value if value.start_with?("#")

        resolved = UriResolver.resolve(base_uri: current_canonical_uri, ref: value)
        document_uri = UriTools.defragment(resolved)
        fragment = UriTools.fragment(resolved)
        local_base_uri = local_uri_map[document_uri]

        return value unless local_base_uri

        if fragment
          "#{local_base_uri}##{fragment}"
        else
          local_base_uri
        end
      end
    end

    module UriResolver
      module_function

      def resolve(base_uri:, ref:)
        URI.join(base_uri, ref).to_s
      rescue URI::InvalidURIError => e
        raise Error, "could not resolve #{ref.inspect} against #{base_uri.inspect}: #{e.message}"
      end
    end

    module UriTools
      module_function

      def defragment(uri_string)
        uri = URI.parse(uri_string)
        uri.fragment = nil
        uri.to_s
      rescue URI::InvalidURIError => e
        raise Error, "invalid URI #{uri_string.inspect}: #{e.message}"
      end

      def fragment(uri_string)
        uri = URI.parse(uri_string)
        uri.fragment
      rescue URI::InvalidURIError => e
        raise Error, "invalid URI #{uri_string.inspect}: #{e.message}"
      end
    end

    module LocalUri
      module_function

      def build(domain_name:, key:)
        "datawires://#{domain_name}/#{key}"
      end
    end

    module KeyMapper
      module_function

      def local_key_for(canonical_uri)
        canonical_uri = UriTools.defragment(canonical_uri)

        case canonical_uri
        when "https://json-schema.org/draft/2020-12/schema"
          "meta/json-schema/2020-12"
        when "https://json-schema.org/draft/2020-12/meta/core"
          "meta/json-schema/2020-12/core"
        when "https://json-schema.org/draft/2020-12/meta/applicator"
          "meta/json-schema/2020-12/applicator"
        when "https://json-schema.org/draft/2020-12/meta/unevaluated"
          "meta/json-schema/2020-12/unevaluated"
        when "https://json-schema.org/draft/2020-12/meta/validation"
          "meta/json-schema/2020-12/validation"
        when "https://json-schema.org/draft/2020-12/meta/meta-data"
          "meta/json-schema/2020-12/meta-data"
        when "https://json-schema.org/draft/2020-12/meta/format-annotation"
          "meta/json-schema/2020-12/format-annotation"
        when "https://json-schema.org/draft/2020-12/meta/content"
          "meta/json-schema/2020-12/content"
        else
          fallback_key_for(canonical_uri)
        end
      end

      def fallback_key_for(canonical_uri)
        canonical_uri = UriTools.defragment(canonical_uri)

        uri = URI.parse(canonical_uri)
        host = uri.host.to_s.gsub(/[^a-zA-Z0-9.-]/, "_")
        path = uri.path.sub(%r{\A/}, "")
        path = "root" if path.empty?
        path = path.gsub(/[^a-zA-Z0-9._\/-]/, "_")

        [ "imports", host, path ].join("/")
      rescue URI::InvalidURIError
        safe = canonical_uri.gsub(/[^a-zA-Z0-9._\/:-]/, "_")
        "imports/unknown/#{safe}"
      end
    end
  end
end

Datawires::ImportJson::CLI.run(ARGV)
