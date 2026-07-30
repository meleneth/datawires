# frozen_string_literal: true

module Voting
  class TallyCountedVote
    class Invalid < StandardError; end

    def self.call(vote:)
      new(vote:).call
    end

    def initialize(vote:)
      raise Invalid, "Vote state must be an object." unless vote.is_a?(Hash)

      @vote = vote
    end

    def call
      validate!
      totals = choices.index_with { 0 }
      ballots.each { |ballot| totals[ballot.fetch("choice")] += 1 }
      yes = totals.fetch("yes")
      no = totals.fetch("no")
      votes_cast = yes + no
      UuidTools.deep_freeze(
        {
          "totals" => totals,
          "threshold" => vote.fetch("threshold").deep_dup,
          "threshold_count" => (votes_cast / 2) + 1,
          "basis_count" => votes_cast,
          "adopted" => yes > no,
          "tie" => yes == no
        }
      )
    end

    private

    attr_reader :vote

    def validate!
      raise Invalid, "Only counted votes can use the counted tally." unless vote["method"] == "counted"
      unless vote["threshold"] == { "kind" => "majority", "basis" => "votes_cast" }
        raise Invalid, "Counted tally requires a majority of votes cast."
      end
      raise Invalid, "Counted vote choices are invalid." unless choices == %w[yes no abstain]

      actor_ids = ballots.map { |ballot| ballot["actor_id"] }
      raise Invalid, "A voter has more than one effective ballot." unless actor_ids.uniq == actor_ids
      unless (actor_ids - Array(vote["eligible_actor_ids"])).empty?
        raise Invalid, "A ballot was cast by an ineligible actor."
      end
      unless ballots.all? { |ballot| choices.include?(ballot["choice"]) }
        raise Invalid, "A ballot contains an invalid choice."
      end
    end

    def ballots
      @ballots ||= Array(vote["ballots"])
    end

    def choices
      @choices ||= Array(vote["choices"])
    end
  end
end
