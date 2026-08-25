# frozen_string_literal: true

module Clusters
  class SyncInstalled
    CLUSTER_ID_PREFIX = "datawires:clusters/"

    def self.call(actor: nil)
      Domain.active.find_each.filter_map do |domain|
        cluster_key = installed_cluster_key(domain)
        next unless cluster_key

        Clusters::SeedDomain.call(domain:, cluster_key:, actor:)
        Documents::ApplyKeyTemplates.call(domain:)
        domain
      end
    end

    def self.installed_cluster_key(domain)
      domain.documents.with_head.filter_map do |document|
        id = document.body["$id"].to_s
        next unless id.start_with?(CLUSTER_ID_PREFIX)

        key = id.delete_prefix(CLUSTER_ID_PREFIX).split("/", 2).first
        key if Clusters::Catalog.include?(key)
      end.tally.max_by { |_key, count| count }&.first
    end
    private_class_method :installed_cluster_key
  end
end
