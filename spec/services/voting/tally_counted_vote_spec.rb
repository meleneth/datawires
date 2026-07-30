# frozen_string_literal: true

require "rails_helper"

RSpec.describe Voting::TallyCountedVote do
  it "counts attributable choices and applies majority of votes cast" do
    vote = vote_state(
      [
        { "actor_id" => SecureRandom.uuid, "choice" => "yes" },
        { "actor_id" => SecureRandom.uuid, "choice" => "yes" },
        { "actor_id" => SecureRandom.uuid, "choice" => "no" },
        { "actor_id" => SecureRandom.uuid, "choice" => "abstain" }
      ]
    )

    result = described_class.call(vote:)

    expect(result).to eq(
      "totals" => { "yes" => 2, "no" => 1, "abstain" => 1 },
      "threshold" => { "kind" => "majority", "basis" => "votes_cast" },
      "threshold_count" => 2,
      "basis_count" => 3,
      "adopted" => true,
      "tie" => false
    )
    expect(result).to be_frozen
  end

  it "rejects ties and excludes abstentions from the votes-cast basis" do
    vote = vote_state(
      [
        { "actor_id" => SecureRandom.uuid, "choice" => "yes" },
        { "actor_id" => SecureRandom.uuid, "choice" => "no" },
        { "actor_id" => SecureRandom.uuid, "choice" => "abstain" }
      ]
    )

    expect(described_class.call(vote:)).to include(
      "basis_count" => 2,
      "threshold_count" => 2,
      "adopted" => false,
      "tie" => true
    )
  end

  it "fails closed for duplicate voters and incompatible requirements" do
    actor_id = SecureRandom.uuid
    duplicate = vote_state(
      [
        { "actor_id" => actor_id, "choice" => "yes" },
        { "actor_id" => actor_id, "choice" => "no" }
      ]
    )

    expect {
      described_class.call(vote: duplicate)
    }.to raise_error(described_class::Invalid, /more than one effective ballot/)
    expect {
      described_class.call(
        vote: vote_state([]).merge("threshold" => { "kind" => "two_thirds", "basis" => "votes_cast" })
      )
    }.to raise_error(described_class::Invalid, /requires a majority/)

    ineligible = vote_state(
      [ { "actor_id" => SecureRandom.uuid, "choice" => "yes" } ],
      eligible_actor_ids: []
    )
    expect {
      described_class.call(vote: ineligible)
    }.to raise_error(described_class::Invalid, /ineligible actor/)
  end

  def vote_state(ballots, eligible_actor_ids: ballots.map { |ballot| ballot["actor_id"] })
    {
      "method" => "counted",
      "choices" => %w[yes no abstain],
      "threshold" => { "kind" => "majority", "basis" => "votes_cast" },
      "eligible_actor_ids" => eligible_actor_ids,
      "ballots" => ballots
    }
  end
end
