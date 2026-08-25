namespace :datawires do
  namespace :clusters do
    desc "Apply current base schemas and affordances to every installed cluster domain"
    task sync: :environment do
      domains = Clusters::SyncInstalled.call
      puts "Synchronized #{domains.length} cluster domain(s): #{domains.map(&:name).join(', ')}"
    end
  end
end
