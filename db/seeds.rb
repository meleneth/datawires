# frozen_string_literal: true

require_relative "seeds/support/document_seed_helper"
require_relative "seeds/support/journey_event_schema"
require_relative "seeds/support/journey_event_example_document"
require_relative "seeds/json_schema_2020_12"
require_relative "seeds/journey_event_edit_affordance"
require_relative "seeds/edit_form_schema"
require_relative "seeds/edit_form_edit_affordance"
require_relative "seeds/journey_item_collection_schema"
require_relative "seeds/journey_item_collection_edit_affordance"
require_relative "seeds/affordance_fixture_examples"
require_relative "seeds/worldbuilder_demo"

Seeds::JsonSchema202012.seed!
Seeds::EditFormSchema.seed!
Seeds::EditFormEditAffordance.seed!
Seeds::JourneyEventSchema.seed!
Seeds::JourneyEventExampleDocument.seed!
Seeds::JourneyEventEditAffordance.seed!
Seeds::JourneyItemCollectionSchema.seed!
Seeds::JourneyItemCollectionEditAffordance.seed!
Seeds::AffordanceFixtureExamples.seed!
Seeds::WorldbuilderDemo.seed!


# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).
#
# Example:
#
#   ["Action", "Comedy", "Drama", "Horror"].each do |genre_name|
#     MovieGenre.find_or_create_by!(name: genre_name)
#   end
