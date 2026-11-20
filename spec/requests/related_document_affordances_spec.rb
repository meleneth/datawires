# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Related document affordances", type: :request do
  let(:domain) { create(:domain) }
  let(:project_schema) { create(:document, :with_schema_head_revision, domain:, key: "project") }
  let(:task_schema) { create(:document, :with_schema_head_revision, domain:, key: "task") }
  let(:note_schema) { create(:document, :with_schema_head_revision, domain:, key: "note") }
  let!(:project_wrapper) { create(:schema_wrapper, document: project_schema) }
  let!(:task_wrapper) { create(:schema_wrapper, document: task_schema) }
  let!(:note_wrapper) { create(:schema_wrapper, document: note_schema) }

  let(:project) do
    create(:document, :with_head_revision, domain:, schema_document: project_schema,
      key: "alpha", title: "Alpha", head_body: { "name" => "Alpha" })
  end
  let(:other_project) do
    create(:document, :with_head_revision, domain:, schema_document: project_schema,
      key: "beta", title: "Beta", head_body: { "name" => "Beta" })
  end

  let(:project_view) do
    create_view(schema_wrapper: project_wrapper, title: "Board", config: {
      "schema_key" => task_schema.key, "foreign_key" => "project_key",
      "group_by" => "status", "groups" => %w[todo doing done], "create_label" => "Create Task"
    })
  end
  let(:task_view) do
    create_view(schema_wrapper: task_wrapper, title: "Details", config: {
      "schema_key" => note_schema.key, "foreign_key" => "task_key",
      "create_label" => "Create Note"
    })
  end

  def create_view(schema_wrapper:, title:, config:)
    backing_document = create(:document, :with_head_revision, domain: schema_wrapper.domain,
      head_body: { "version" => 1, "renderer" => "related_documents", "title" => title, "config" => config })
    create(:view_affordance, schema_wrapper:, view_document: backing_document, title:)
  end

  def create_task(project_key:, key:, status: "todo")
    create(:document, :with_head_revision, domain:, schema_document: task_schema,
      key:, title: key, head_body: { "title" => key, "status" => status, "project_key" => project_key })
  end

  it "renders a reusable Project board with only its own tasks and a Create Task button" do
    own = create_task(project_key: project.key, key: "alpha-task", status: "doing")
    create_task(project_key: other_project.key, key: "beta-task", status: "todo")
    view = project_view
    task_view

    get document_view_affordance_path(project, view)

    expect(response).to have_http_status(:ok)
    expect(response.body).to include("Create Task", "Doing", own.title)
    expect(response.body).not_to include("beta-task")
    expect(response.body).to include(create_related_document_view_affordance_path(project, view))
    expect(response.body).to include(document_view_affordance_path(own, task_view))
  end

  it "creates a Task already linked to the source Project and opens its draft" do
    view = project_view

    expect {
      post create_related_document_view_affordance_path(project, view)
    }.to change(Document.where(schema_document: task_schema), :count).by(1)

    created = Document.where(schema_document: task_schema).order(:created_at).last
    draft = created.drafts.sole
    expect(created.body).to eq("project_key" => project.key)
    expect(draft.body).to eq("project_key" => project.key)
    expect(response).to redirect_to(draft_path(draft))
  end

  it "creates a Note linked to the current Task, not merely its Project" do
    task = create_task(project_key: project.key, key: "alpha-task")
    view = task_view

    expect {
      post create_related_document_view_affordance_path(task, view)
    }.to change(Document.where(schema_document: note_schema), :count).by(1)

    note = Document.where(schema_document: note_schema).order(:created_at).last
    expect(note.body).to eq("task_key" => task.key)
    expect(note.drafts.sole.body).to eq("task_key" => task.key)
  end

  it "shows a new project with the same board affordance without provisioning a Board" do
    view = project_view
    before_count = Board.count

    get document_view_affordance_path(other_project, view)

    expect(response).to have_http_status(:ok)
    expect(response.body).to include("Create Task")
    expect(response.body).to include("No documents yet.")
    expect(Board.count).to eq(before_count)
  end

  it "rejects creation when the actor lacks permission" do
    view = project_view
    allow_any_instance_of(User).to receive(:can?).with(
      :create_document, schema_wrapper: task_wrapper
    ).and_return(false)

    project
    expect {
      post create_related_document_view_affordance_path(project, view)
    }.not_to change(Document, :count)

    expect(response).to redirect_to(document_view_affordance_path(project, view))
    expect(flash[:alert]).to include("not allowed to create document")
  end

  it "rejects a view with a missing related-document schema without creating anything" do
    view = create_view(schema_wrapper: project_wrapper, title: "Missing", config: {
      "schema_key" => "does-not-exist", "foreign_key" => "project_key"
    })
    project
    expect {
      post create_related_document_view_affordance_path(project, view)
    }.not_to change(Document, :count)

    expect(response).to redirect_to(document_view_affordance_path(project, view))
    expect(flash[:alert]).to include("Related document schema was not found")
  end

  it "does not permit invoking a view affordance from another source schema" do
    view = project_view
    task = create_task(project_key: project.key, key: "alpha-task")

    post create_related_document_view_affordance_path(task, view)
    expect(response).to have_http_status(:not_found)
  end

  it "does not allow contextual creation for a renderer that is not related_documents" do
    view = create_view(schema_wrapper: project_wrapper, title: "Other", config: {
      "schema_key" => task_schema.key, "foreign_key" => "project_key"
    })
    revision = view.view_document.revisions.create!(
      parent_revision: view.head_revision,
      body: { "version" => 1, "title" => "Other", "renderer" => "mud_player", "config" => {} }
    )
    view.view_document.update!(head_revision: revision)

    project
    expect {
      post create_related_document_view_affordance_path(project, view)
    }.not_to change(Document, :count)

    expect(response).to redirect_to(document_view_affordance_path(project, view))
    expect(flash[:alert]).to include("does not support contextual creation")
  end
end
