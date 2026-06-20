# frozen_string_literal: true

module Seeds
  module JourneyEventSchema
    module_function

    DOMAIN_NAME = "Journey"
    DOCUMENT_KEY = "event"
    DOCUMENT_TITLE = "Journey Event"

    def seed!
      domain = DocumentSeedHelper.ensure_domain!(name: DOMAIN_NAME)

      document = DocumentSeedHelper.ensure_document_with_revision!(
        domain:,
        key: DOCUMENT_KEY,
        title: DOCUMENT_TITLE,
        body: schema_body,
        message: "Seed Journey Event schema"
      )

      SchemaWrapper.find_or_create_by!(document:)
    end

    def schema_body
      {
        "$id" => "http://journey/event",
        "type" => "object",
        "title" => DOCUMENT_TITLE,
        "$schema" => "https://json-schema.org/draft/2020-12/schema",
        "examples" => [
          {
            "act" => "Act II",
            "area" => "Lost City",
            "notes" => "Single-player drop. Worth logging.",
            "title" => "Found Sander's RipRap",
            "notable" => true,
            "item_name" => "Sander's RipRap",
            "difficulty" => "Normal",
            "event_type" => "item_find",
            "occurred_at" => "2026-03-27T20:30:00Z",
            "item_quality" => "Set",
            "character_name" => "Boyle",
            "character_class" => "Warlock",
            "character_level" => 28
          }
        ],
        "required" => [
          "title",
          "event_type",
          "character_name",
          "character_class",
          "character_level",
          "difficulty",
          "act",
          "area"
        ],
        "properties" => {
          "act" => {
            "enum" => [
              "Act I",
              "Act II",
              "Act III",
              "Act IV",
              "Act V"
            ],
            "type" => "string"
          },
          "area" => {
            "enum" => [
              "Rogue Encampment",
              "Blood Moor",
              "Den of Evil",
              "Cold Plains",
              "Burial Grounds",
              "Stony Field",
              "Dark Wood",
              "Black Marsh",
              "Forgotten Tower",
              "Tamoe Highlands",
              "The Pit",
              "Monastery Gate",
              "Outer Cloister",
              "Barracks",
              "Jail",
              "Inner Cloister",
              "Cathedral",
              "Catacombs",
              "Tristram",
              "Lut Gholein",
              "Sewers",
              "Rocky Waste",
              "Stony Tomb",
              "Dry Hills",
              "Halls of the Dead",
              "Far Oasis",
              "Maggot Lair",
              "Lost City",
              "Ancient Tunnels",
              "Valley of Snakes",
              "Claw Viper Temple",
              "Arcane Sanctuary",
              "Canyon of the Magi",
              "Tal Rasha's Tomb",
              "Duriel's Lair",
              "Kurast Docks",
              "Spider Forest",
              "Spider Cavern",
              "Great Marsh",
              "Flayer Jungle",
              "Flayer Dungeon",
              "Lower Kurast",
              "Kurast Bazaar",
              "Upper Kurast",
              "Travincal",
              "Durance of Hate",
              "Pandemonium Fortress",
              "Outer Steppes",
              "Plains of Despair",
              "City of the Damned",
              "River of Flame",
              "Chaos Sanctuary",
              "Harrogath",
              "Bloody Foothills",
              "Frigid Highlands",
              "Abaddon",
              "Arreat Plateau",
              "Pit of Acheron",
              "Crystalline Passage",
              "Frozen River",
              "Glacial Trail",
              "Drifter Cavern",
              "Frozen Tundra",
              "Infernal Pit",
              "Ancients' Way",
              "Icy Cellar",
              "Arreat Summit",
              "Nihlathak's Temple",
              "Halls of Anguish",
              "Halls of Pain",
              "Halls of Vaught",
              "Worldstone Keep",
              "Throne of Destruction",
              "Worldstone Chamber",
              "The Secret Cow Level"
            ],
            "type" => "string"
          },
          "notes" => {
            "type" => "string",
            "maxLength" => 4000
          },
          "title" => {
            "type" => "string",
            "maxLength" => 120,
            "minLength" => 1,
            "description" => "Short summary shown in lists."
          },
          "notable" => {
            "type" => "boolean",
            "default" => false
          },
          "item_name" => {
            "type" => "string",
            "maxLength" => 120
          },
          "difficulty" => {
            "enum" => [
              "Normal",
              "Nightmare",
              "Hell"
            ],
            "type" => "string"
          },
          "event_type" => {
            "enum" => [
              "item_find",
              "level_up",
              "quest_complete",
              "boss_kill",
              "death",
              "milestone",
              "note"
            ],
            "type" => "string",
            "default" => "item_find"
          },
          "occurred_at" => {
            "type" => "string",
            "format" => "date-time"
          },
          "item_quality" => {
            "enum" => [
              "Normal",
              "Magic",
              "Rare",
              "Set",
              "Unique",
              "Crafted",
              "Rune",
              "Gem",
              "Quest",
              "Other"
            ],
            "type" => "string"
          },
          "character_name" => {
            "enum" => [
              "Boyle"
            ],
            "type" => "string"
          },
          "character_class" => {
            "enum" => [
              "Amazon",
              "Assassin",
              "Barbarian",
              "Druid",
              "Necromancer",
              "Paladin",
              "Sorceress",
              "Warlock"
            ],
            "type" => "string"
          },
          "character_level" => {
            "type" => "integer",
            "maximum" => 99,
            "minimum" => 1
          }
        },
        "additionalProperties" => false
      }
    end
  end
end
