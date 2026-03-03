# frozen_string_literal: true

require "rails_helper"

RSpec.describe Revision, type: :model do
  it "requires body" do
    rev = build(:revision, body: nil)
    expect(rev).not_to be_valid
  end

  it "requires parent_revision to belong to the same document" do
    doc1 = create(:document)
    doc2 = create(:document)
    parent = create(:revision, document: doc1)

    child = build(:revision, document: doc2, parent_revision: parent)
    expect(child).not_to be_valid
    expect(child.errors[:parent_revision]).to be_present
  end

  it "is immutable after creation" do
    rev = create(:revision, body: { "a" => 1 })
    expect { rev.update!(body: { "a" => 2 }) }
      .to raise_error(ActiveRecord::ReadOnlyRecord)
  end
end
