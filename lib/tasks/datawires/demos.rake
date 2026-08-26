# frozen_string_literal: true

namespace :datawires do
  namespace :demos do
    desc "Install or refresh the public Fairlanes project showcase"
    task fairlanes: :environment do
      actor = User.find_by(name: ENV.fetch("ACTOR", "meleneth")) || User.find_by!(name: "devUser")
      domain = Demos::FairlanesProject.call(actor:)
      puts "Fairlanes showcase: #{Rails.application.routes.url_helpers.domain_path(domain)}"
      puts "Board: #{Rails.application.routes.url_helpers.board_path(domain.project_affordance.default_board)}"
    end
  end
end
