# frozen_string_literal: true

require "rails_helper"

RSpec.describe Boards::ActionResolution do
  it "resolves an authorized schema and named edit affordance in the board domain" do
    board = create(:board)
    schema = create(:document, :with_schema_head_revision, domain: board.schema_wrapper.domain, key: "proposal")
    wrapper = create(:schema_wrapper, document: schema)
    affordance = create(:edit_affordance, schema_wrapper: wrapper, title: "Submit")
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
    actor = actor_context(can: true)

    result = described_class.call(board:, action: board.projection.actions.first, actor:)

    expect(result).to be_available
    expect(result.schema_wrapper).to eq(wrapper)
    expect(result.edit_affordance).to eq(affordance)
  end

  it "honors hidden authorization denial and keeps command actions unavailable" do
    board = create(:board)
    schema = create(:document, :with_schema_head_revision, domain: board.schema_wrapper.domain, key: "proposal")
    create(:schema_wrapper, document: schema)
    configure_actions(
      board,
      [
        {
          "id" => "submit",
          "kind" => "open_edit_affordance",
          "title" => "Submit",
          "config" => { "schema_key" => "proposal", "when_denied" => "hidden" }
        },
        {
          "id" => "open",
          "kind" => "invoke_command",
          "title" => "Open meeting",
          "config" => { "command" => "open_meeting" }
        }
      ]
    )
    actor = actor_context(can: false)

    denied = described_class.call(board:, action: board.projection.actions.first, actor:)
    command = described_class.call(board:, action: board.projection.actions.second, actor:)

    expect(denied).to be_hidden
    expect(denied.reason).to eq("The actor is not allowed to create document.")
    expect(command).not_to be_available
    expect(command.reason).to eq("Domain commands are not registered yet.")
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

  def actor_context(can:)
    user = create(:user)
    allow(user).to receive(:can?).and_return(can)
    claims = Identity::Claims.new(issuer: "spec", subject: user.id, name: "Spec Actor")
    ActorContext.new(user:, claims:)
  end
end
