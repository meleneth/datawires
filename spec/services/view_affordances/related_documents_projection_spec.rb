# frozen_string_literal: true

require "rails_helper"

RSpec.describe ViewAffordances::RelatedDocumentsProjection do
  let(:domain) { create(:domain) }
  let(:project_schema) { create(:document, :with_schema_head_revision, domain:, key: "project") }
  let(:task_schema) { create(:document, :with_schema_head_revision, domain:, key: "task") }
  let!(:task_wrapper) { create(:schema_wrapper, document: task_schema) }
  let(:project) do
    create(:document, :with_head_revision, domain:, schema_document: project_schema,
      key: "project-one", title: "Project One", head_body: { "name" => "Project One" })
  end
  let(:other_project) do
    create(:document, :with_head_revision, domain:, schema_document: project_schema,
      key: "project-two", title: "Project Two", head_body: { "name" => "Project Two" })
  end
  let(:view) do
    view_document = create(:document, :with_head_revision, domain:, head_body: {
      "version" => 1, "title" => "Board", "renderer" => "related_documents",
      "config" => { "schema_key" => "task", "foreign_key" => "project_key",
        "group_by" => "status", "groups" => %w[todo doing done], "create_label" => "Create Task" }
    })
    create(:view_affordance, schema_wrapper: create(:schema_wrapper, document: project_schema),
      view_document:, title: "Board")
  end

  def task(key:, project_key:, status:)
    create(:document, :with_head_revision, domain:, schema_document: task_schema,
      key:, title: key, head_body: { "title" => key, "project_key" => project_key, "status" => status })
  end

  it "filters by the actual source document and groups children in configured order" do
    first = task(key: "first", project_key: project.key, status: "doing")
    second = task(key: "second", project_key: project.key, status: "todo")
    task(key: "unrelated", project_key: other_project.key, status: "todo")

    projection = described_class.call(document: project, view_affordance: view)

    expect(projection.renderer).to eq("related_documents")
    expect(projection.data.fetch("groups").keys).to eq(%w[todo doing done])
    expect(projection.data.fetch("groups").fetch("todo")).to eq([ second ])
    expect(projection.data.fetch("groups").fetch("doing")).to eq([ first ])
    expect(projection.data.fetch("groups").fetch("done")).to eq([])
    expect(projection.data.fetch("create_label")).to eq("Create Task")
  end

  it "works for a new project with no additional board provisioning" do
    task(key: "existing", project_key: other_project.key, status: "doing")

    projection = described_class.call(document: project, view_affordance: view)
    expect(projection.data.fetch("groups").values.flatten).to be_empty
  end

  it "does not leak similarly keyed documents from other domains" do
    another_domain = create(:domain)
    another_schema = create(:document, :with_schema_head_revision, domain: another_domain, key: "task")
    create(:schema_wrapper, document: another_schema)
    create(:document, :with_head_revision, domain: another_domain, schema_document: another_schema,
      key: "outsider", head_body: { "project_key" => project.key, "status" => "todo" })

    projection = described_class.call(document: project, view_affordance: view)
    expect(projection.data.fetch("groups").values.flatten).to be_empty
  end

  it "reports an unavailable child schema without fetching unrelated documents" do
    body = view.view_document.body.deep_dup
    body["config"]["schema_key"] = "missing"
    revision = view.view_document.revisions.create!(parent_revision: view.head_revision, body:)
    view.view_document.update!(head_revision: revision)

    projection = described_class.call(document: project, view_affordance: view)
    expect(projection.data.fetch("schema_found")).to be(false)
    expect(projection.data.fetch("groups").values.flatten).to be_empty
  end
end
