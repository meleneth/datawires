require "rails_helper"

RSpec.describe Domain, type: :model do
  describe ".visible_to" do
    it "returns public, legacy ownerless, and private domains owned by the user" do
      owner = create(:user)
      other = create(:user)
      owned_private = create(:domain, owner: owner, public: false)
      public_domain = create(:domain, owner: other, public: true)
      legacy_domain = create(:domain, owner: nil, public: false)
      create(:domain, owner: other, public: false)

      expect(described_class.visible_to(owner)).to contain_exactly(owned_private, public_domain, legacy_domain)
    end
  end

  describe "#visible_to?" do
    it "allows public domains and owner-private domains" do
      owner = create(:user)
      other = create(:user)
      domain = build(:domain, owner: owner, public: false)

      expect(domain).to be_visible_to(owner)
      expect(domain).not_to be_visible_to(other)

      domain.public = true
      expect(domain).to be_visible_to(other)
    end
  end
end
