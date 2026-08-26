# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Domain export/import" do
  it "exports and imports a repository domain with revision and commit history intact" do
    actor = create(:user)
    domain = create(:domain, name: "Rules Archive")
    Clusters::SeedDomain.call(domain: domain, cluster_key: Clusters::Catalog::ROBERTS_RULES, actor: actor)
    first_commit = domain.reload.head_domain_commit
    body_schema = domain.documents.find_by!(key: Bodies::Schema::KEY)
    body_document = create(
      :document,
      domain: domain,
      key: "assembly",
      title: "Assembly",
      schema_document: body_schema
    )
    original_revision = body_document.revisions.create!(
      body: { "name" => "Assembly" },
      message: "Draft assembly",
      created_by: actor
    )
    body_document.update!(head_revision: original_revision)
    amended_revision = body_document.revisions.create!(
      parent_revision: original_revision,
      body: { "name" => "General Assembly", "description" => "Repository fixture" },
      message: "Rename assembly",
      created_by: actor
    )
    body_document.update!(head_revision: amended_revision)
    second_commit = DomainCommits::Create.call(domain: domain, message: "Rename assembly", actor: actor)

    archive = DomainExports::Export.call(domain: domain)

    expect(archive.to_json).not_to match(uuid_pattern)
    imported = DomainExports::Import.call(archive: archive, name: "Rules Archive Copy")

    expect(imported).to have_attributes(
      name: "Rules Archive Copy",
      repository_mode: true
    )
    expect(imported.id).not_to eq(domain.id)
    imported_body = imported.documents.find_by!(key: "assembly")
    expect(imported_body.id).not_to eq(body_document.id)
    expect(imported_body.head_revision_id).not_to eq(amended_revision.id)
    expect(imported_body.head_revision.body).to eq(amended_revision.body)
    expect(imported_body.schema_document.key).to eq(Bodies::Schema::KEY)
    expect(imported.domain_commits.order(:created_at).pluck(:id)).not_to eq([ first_commit.id, second_commit.id ])
    expect(imported.head_domain_commit.state_hash).to eq(second_commit.state_hash)
    expect(imported.head_domain_commit.parent_domain_commit.state_hash).to eq(first_commit.state_hash)
    expect(imported.head_domain_commit.domain_commit_documents.find_by!(document_key: "assembly")).to have_attributes(
      revision_hash: a_string_matching(/\A\h{64}\z/)
    )
    expect(imported.documents.find_by!(key: Meetings::Schema::KEY).schema_wrapper.edit_affordances).to be_empty
  end

  it "rejects unsupported archive formats" do
    expect {
      DomainExports::Import.call(archive: { "format" => "nope", "version" => 1 })
    }.to raise_error(ArgumentError, "unsupported domain archive format")
  end

  it "round trips project, board, source, run, observation, and credential requirements without secrets" do
    domain = create(:domain, name: "Telemetry")
    project = Projects::Install.call(domain:)
    workspace_schema = create(:document, :with_schema_head_revision, domain:, key: "workspace")
    board = create(:board, schema_wrapper: create(:schema_wrapper, document: workspace_schema))
    project.update!(default_board: board)
    credential = SourceCredential.create!(domain:, name: "api", secret: { "headers" => { "X-Api-Key" => "top-secret" } })
    source = create(:source, domain:, source_credential: credential)
    run = source.source_runs.create!(configuration_revision: source.head_revision, trigger: "manual",
      adapter: "http_json", adapter_version: "1", idempotency_key: "archive-run", status: "succeeded",
      observation_count: 1)
    source.observations.create!(domain:, source_run: run, configuration_revision: source.head_revision,
      observation_type: "metric", metric_key: "temperature", numeric_value: 12.5, payload: { "value" => 12.5 },
      observed_at: Time.current, effective_at: Time.current, recorded_at: Time.current,
      provenance: { "configuration_revision_id" => source.head_revision.id })

    archive = DomainExports::Export.call(domain:)

    expect(archive["version"]).to eq(4)
    expect(archive["credential_requirements"]).to eq([ "api" ])
    expect(archive.to_json).not_to include("top-secret")
    imported = DomainExports::Import.call(archive:, name: "Telemetry Copy")

    expect(imported.project_affordance.default_board.title).to eq(board.title)
    expect(imported.sources.sole.source_credential).to be_nil
    expect(imported.sources.sole.source_runs.sole.configuration_revision).to eq(imported.sources.sole.head_revision)
    expect(imported.observations.sole.numeric_value).to eq(12.5)
  end

  it "round trips reusable queries, dispatches extension contributors, and can omit operational history" do
    contributor = Class.new do
      const_set(:VERSION, 1)
      define_singleton_method(:export) { |domain:| { "domain_name" => domain.name } }
      define_singleton_method(:import) { |domain:, payload:| domain.update!(public: payload["make_public"] == true) }
    end
    Datawires::Providers.archive_contributors.register("spec", contributor)
    domain = create(:domain, name: "Definitions")
    query = VersionedDefinitions::Create.call(domain:, actor: domain.owner, schema: Queries::Schema,
      key: "latest", title: "Latest", wrapper_class: QueryDefinition, document_association: :query_document,
      body: { "version" => 1, "key" => "latest", "title" => "Latest", "metric_key" => "temperature",
        "aggregate" => "last" })
    source = create(:source, domain:)
    source.source_runs.create!(configuration_revision: source.head_revision, trigger: "manual",
      adapter: source.adapter, adapter_version: "1", idempotency_key: "excluded")

    archive = DomainExports::Export.call(domain:, include_operational_history: false)

    expect(archive).to include("source_runs" => [], "observations" => [])
    expect(archive.dig("extensions", "spec", "payload")).to eq("domain_name" => "Definitions")
    archive["extensions"]["spec"]["payload"] = { "make_public" => true }
    imported = DomainExports::Import.call(archive:, name: "Definitions Copy")
    expect(imported.query_definitions.sole.body).to eq(query.body)
    expect(imported).to be_public
  ensure
    Datawires::Providers.archive_contributors.unregister("spec")
  end

  def uuid_pattern
    /\b[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}\b/i
  end
end
