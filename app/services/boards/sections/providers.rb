# frozen_string_literal: true

module Boards
  module Sections
    module Providers
      class SimpleProvider
        def self.call(board:, section:, actor:)
          service.call(board:, section:)
        end
      end

      class DocumentCollectionProvider < SimpleProvider
        def self.service = Boards::DocumentCollection
      end

      class MeetingCollectionProvider < SimpleProvider
        def self.service = Boards::MeetingCollection
      end

      class ProposalCollectionProvider < SimpleProvider
        def self.service = Boards::ProposalCollection
      end

      class MembershipCollectionProvider
        def self.call(board:, section:, actor:)
          Boards::MembershipCollection.call(board:, section:, actor:)
        end
      end

      class RoleAssignmentCollectionProvider
        def self.call(board:, section:, actor:)
          Boards::RoleAssignmentCollection.call(board:, section:, actor:)
        end
      end
    end
  end
end
