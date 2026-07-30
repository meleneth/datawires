# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Boards", type: :request do
  it "creates and opens a board from the schema workshop" do
    schema_wrapper = create(:schema_wrapper)

    expect {
      post schema_boards_path(schema_wrapper), params: { title: "Datawires Board" }
    }.to change(Board, :count).by(1)
      .and change(Document, :count).by(2)
      .and change(Draft, :count).by(1)

    board = Board.order(:created_at).last
    expect(response).to redirect_to(board_path(board))

    get board_path(board)

    expect(response).to have_http_status(:ok)
    expect(response.body).to include("Datawires Board")
    expect(response.body).to include("This board has no sections yet.")
    expect(response.body).to include("Schema workshop")
  end

  it "prefers the default board while preserving an explicit workshop route" do
    board = create(:board)
    board.schema_wrapper.update!(default_board: board)

    get schema_path(board.schema_wrapper)
    expect(response).to redirect_to(board_path(board))

    get schema_path(board.schema_wrapper, workshop: 1)
    expect(response).to have_http_status(:ok)
    expect(response.body).to include("New board")
  end

  it "renders filtered collections with document navigation and empty states" do
    domain = create(:domain)
    proposal_schema = create(:document, :with_schema_head_revision, domain:, key: "proposal")
    create(:schema_wrapper, document: proposal_schema)
    open_proposal = create(:document, :with_head_revision, domain:, schema_document: proposal_schema, key: "open-proposal", title: "Open Proposal", head_body: { "status" => "open" })
    create(:document, :with_head_revision, domain:, schema_document: proposal_schema, key: "closed-proposal", title: "Closed Proposal", head_body: { "status" => "closed" })
    board_schema = create(:document, :with_schema_head_revision, domain:, key: Boards::Schema::KEY, head_body: Boards::Schema::BODY)
    create(:schema_wrapper, document: board_schema)
    workspace_schema = create(:document, :with_schema_head_revision, domain:, key: "workspace")
    workspace_wrapper = create(:schema_wrapper, document: workspace_schema)
    board_document = create(
      :document,
      :with_head_revision,
      domain:,
      schema_document: board_schema,
      head_body: {
        "version" => 1,
        "title" => "Workspace",
        "sections" => [
          {
            "id" => "open",
            "kind" => "document_collection",
            "title" => "Open proposals",
            "config" => {
              "schema_key" => "proposal",
              "filters" => [ { "path" => "/status", "value" => "open" } ],
              "empty_state" => "Nothing pending."
            }
          },
          {
            "id" => "missing",
            "kind" => "document_collection",
            "title" => "Unscheduled proposals",
            "config" => {
              "schema_key" => "proposal",
              "filters" => [ { "path" => "/status", "value" => "unscheduled" } ],
              "empty_state" => "Nothing unscheduled."
            }
          }
        ],
        "actions" => []
      }
    )
    board = create(:board, schema_wrapper: workspace_wrapper, board_document:, title: "Workspace")

    get board_path(board)

    expect(response).to have_http_status(:ok)
    expect(response.body).to include("Open Proposal")
    expect(response.body).to include(document_path(open_proposal))
    expect(response.body).not_to include("Closed Proposal")
    expect(response.body).not_to include("Nothing pending.")
    expect(response.body).to include("Nothing unscheduled.")
  end

  it "executes an available edit action through its server-side resolution" do
    board = create(:board)
    domain = board.schema_wrapper.domain
    proposal_schema = create(:document, :with_schema_head_revision, domain:, key: "proposal")
    proposal_wrapper = create(:schema_wrapper, document: proposal_schema)
    affordance = create(:edit_affordance, schema_wrapper: proposal_wrapper, title: "Submit")
    configure_actions(
      board,
      [
        {
          "id" => "submit",
          "kind" => "open_edit_affordance",
          "title" => "Submit proposal",
          "config" => { "schema_key" => "proposal", "edit_affordance" => "Submit" }
        }
      ]
    )

    get board_path(board)
    expect(response.body).to include("Submit proposal")

    expect {
      post board_action_path(board, "submit")
    }.to change(Document.where(schema_document: proposal_schema), :count).by(1)

    draft = Draft.order(:created_at).last
    expect(response).to redirect_to(draft_path(draft, edit_affordance_id: affordance.id))
  end

  it "reauthorizes a board action at execution time" do
    board = create(:board)
    domain = board.schema_wrapper.domain
    proposal_schema = create(:document, :with_schema_head_revision, domain:, key: "proposal")
    create(:schema_wrapper, document: proposal_schema)
    configure_actions(
      board,
      [
        {
          "id" => "submit",
          "kind" => "open_edit_affordance",
          "title" => "Submit proposal",
          "config" => { "schema_key" => "proposal" }
        }
      ]
    )
    allow_any_instance_of(User).to receive(:can?).with(
      :create_document,
      schema_wrapper: an_instance_of(SchemaWrapper),
      board:
    ).and_return(false)

    expect {
      post board_action_path(board, "submit")
    }.not_to change(Document.where(schema_document: proposal_schema), :count)

    expect(response).to redirect_to(board_path(board))
    expect(flash[:alert]).to eq("The actor is not allowed to create document.")
  end

  def configure_actions(board, actions)
    body = board.body.deep_dup
    body["actions"] = actions
    revision = board.board_document.revisions.create!(
      parent_revision: board.head_revision,
      body:
    )
    board.board_document.update!(head_revision: revision)
  end
end
