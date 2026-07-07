# frozen_string_literal: true

module Seeds
  module PrivateMudDemo
    module_function

    DOMAIN_ID = "20000000-0000-4000-8000-000000000000"
    DOMAIN_NAME = "Private MUD Demo"
    MESSAGE = "Seed private MUD demo"

    DOCUMENT_IDS = {
      "atrium" => "20000000-0000-4000-8000-000000000001",
      "library" => "20000000-0000-4000-8000-000000000002",
      "workshop" => "20000000-0000-4000-8000-000000000003",
      "warden" => "20000000-0000-4000-8000-000000000101",
      "guest" => "20000000-0000-4000-8000-000000000102",
      "brass-key" => "20000000-0000-4000-8000-000000000201",
      "ledger" => "20000000-0000-4000-8000-000000000202",
      "demo-world" => "20000000-0000-4000-8000-000000000301",
      "wizard-gate" => "20000000-0000-4000-8000-000000000401",
      "mirror-hall" => "20000000-0000-4000-8000-000000000402",
      "star-vault" => "20000000-0000-4000-8000-000000000403",
      "wizard-victory" => "20000000-0000-4000-8000-000000000404",
      "thorn-death" => "20000000-0000-4000-8000-000000000405",
      "ash-death" => "20000000-0000-4000-8000-000000000406",
      "glass-death" => "20000000-0000-4000-8000-000000000407",
      "echo-death" => "20000000-0000-4000-8000-000000000408",
      "starfall-death" => "20000000-0000-4000-8000-000000000409",
      "void-death" => "20000000-0000-4000-8000-000000000410",
      "domain-home" => "20000000-0000-4000-8000-000000000901"
    }.freeze

    def seed!
      actor = User.find_or_create_by!(id: ApplicationController::DEV_USER_ID) do |user|
        user.name = "devUser"
        user.avatar = "https://api.dicebear.com/7.x/pixel-art/png?seed=devUser"
      end
      domain = ensure_domain!
      ensure_home_document!(domain:)

      Clusters::SeedDomain.call(domain: domain, cluster_key: Clusters::Catalog::PRIVATE_MUD, actor: actor)

      schema_documents = domain.documents.where(key: %w[mud-room mud-character mud-item mud-world mud-choice-room]).index_by(&:key)
      rooms.each { |definition| ensure_document!(domain:, schema_documents:, schema_key: "mud-room", definition:) }
      characters.each { |definition| ensure_document!(domain:, schema_documents:, schema_key: "mud-character", definition:) }
      items.each { |definition| ensure_document!(domain:, schema_documents:, schema_key: "mud-item", definition:) }
      worlds.each { |definition| ensure_document!(domain:, schema_documents:, schema_key: "mud-world", definition:) }
      choice_rooms.each { |definition| ensure_document!(domain:, schema_documents:, schema_key: "mud-choice-room", definition:) }
      ensure_home_document!(domain:)

      domain
    end

    def ensure_domain!
      domain = Domain.find_or_initialize_by(id: DOMAIN_ID)
      domain.name = DOMAIN_NAME
      domain.repository_mode = false
      domain.save! if domain.new_record? || domain.changed?
      domain
    rescue ActiveRecord::RecordNotUnique, ActiveRecord::RecordInvalid
      Domain.find_by!(name: DOMAIN_NAME)
    end

    def ensure_document!(domain:, schema_documents:, schema_key:, definition:)
      document = domain.documents.find_or_initialize_by(key: definition.fetch(:key))
      document.id = DOCUMENT_IDS.fetch(definition.fetch(:key)) if document.new_record?
      document.title = definition.fetch(:title)
      document.save! if document.new_record? || document.changed?

      body = definition.fetch(:body)
      if document.body != body
        revision = document.revisions.create!(
          body: body,
          parent_revision: document.head_revision,
          message: MESSAGE
        )
        document.update!(head_revision: revision)
      end

      schema_document = schema_documents.fetch(schema_key)
      document.update!(schema_document: schema_document) if document.schema_document != schema_document
      DocumentIndexes::Rebuild.call(document: document)
      document
    end

    def ensure_home_document!(domain:)
      document = domain.documents.find_or_initialize_by(key: "domain-home")
      document.id = DOCUMENT_IDS.fetch("domain-home") if document.new_record?
      document.title = "Domain Home"
      document.save! if document.new_record? || document.changed?

      body = home_body
      if document.body != body
        revision = document.revisions.create!(
          body: body,
          parent_revision: document.head_revision,
          message: MESSAGE
        )
        document.update!(head_revision: revision)
      end

      schema_document = domain.documents.find_by(key: "domain-home-page")
      document.update!(schema_document: schema_document) if schema_document && document.schema_document != schema_document
      document
    end

    def rooms
      [
        room(
          "atrium",
          "Lantern Atrium",
          "Manor",
          "A private stone atrium lit by steady brass lanterns. Drafts move through carved archways.",
          [
            exit_to("east", "library", "Library", "A quiet passage lined with old maps."),
            exit_to("down", "workshop", "Workshop stairs", "Iron steps descend under the fountain.")
          ]
        ),
        room(
          "library",
          "Map Library",
          "Manor",
          "Tall shelves hold annotated charts of places that may or may not exist yet.",
          [
            exit_to("west", "atrium", "Atrium", "The lantern glow is visible through the arch.")
          ]
        ),
        room(
          "workshop",
          "Clockwork Workshop",
          "Underworks",
          "Benches carry half-built locks, ticking boxes, and carefully labeled experiments.",
          [
            exit_to("up", "atrium", "Atrium stairs", "The iron stairs climb toward warmer light.")
          ]
        )
      ]
    end

    def characters
      [
        {
          key: "guest",
          title: "Guest Explorer",
          body: {
            "name" => "Guest Explorer",
            "character_type" => "player",
            "description" => "A demo player character for trying the read-only play view.",
            "disposition" => "curious",
            "location_room_key" => "atrium",
            "inventory_item_keys" => [ "brass-key" ],
            "notes" => "Open the Play view from this character to see their current room and inventory."
          }
        },
        {
          key: "warden",
          title: "Atrium Warden",
          body: {
            "name" => "Atrium Warden",
            "character_type" => "npc",
            "description" => "A patient caretaker who notices every door that opens.",
            "disposition" => "watchful",
            "location_room_key" => "atrium",
            "inventory_item_keys" => [],
            "notes" => "NPC visible in the atrium play view."
          }
        }
      ]
    end

    def items
      [
        {
          key: "brass-key",
          title: "Brass Key",
          body: {
            "name" => "Brass Key",
            "item_type" => "key",
            "description" => "A small key stamped with a lantern mark.",
            "portable" => true,
            "location_kind" => "character",
            "location_key" => "guest",
            "notes" => "Shown in the guest character inventory."
          }
        },
        {
          key: "ledger",
          title: "Room Ledger",
          body: {
            "name" => "Room Ledger",
            "item_type" => "book",
            "description" => "A heavy ledger listing every room that has been authored so far.",
            "portable" => false,
            "location_kind" => "room",
            "location_key" => "library",
            "notes" => "Shown in the library room inventory."
          }
        }
      ]
    end

    def worlds
      [
        {
          key: "demo-world",
          title: "Lantern House",
          body: {
            "name" => "Lantern House",
            "summary" => "A small private MUD demo for room, character, item, and play affordances.",
            "start_room_key" => "atrium",
            "default_character_key" => "guest",
            "notes" => "The world document provides a stable start room for play."
          }
        }
      ]
    end

    def choice_rooms
      [
        choice_room(
          "wizard-gate",
          "Wizard's Gate",
          "challenge",
          "Room 1",
          "A bronze gate speaks through the wall. Three runes glow beneath its lock.",
          [
            choice("Touch the thorn rune", "It promises a shortcut through the hedge.", "death", "thorn-death"),
            choice("Touch the moon rune", "It opens a silver stair beyond the gate.", "advance", "mirror-hall"),
            choice("Touch the ash rune", "It smells faintly of old smoke.", "death", "ash-death")
          ]
        ),
        choice_room(
          "mirror-hall",
          "Mirror Hall",
          "challenge",
          "Room 2",
          "Three mirrors wait in a silent hall. Only one reflection moves when you do.",
          [
            choice("Step into the laughing mirror", "The glass smiles before you do.", "death", "glass-death"),
            choice("Step into the still mirror", "The frame stays cold and black.", "death", "echo-death"),
            choice("Step into the listening mirror", "It repeats your heartbeat and opens.", "advance", "star-vault")
          ]
        ),
        choice_room(
          "star-vault",
          "Star Vault",
          "challenge",
          "Room 3",
          "The final vault holds three suspended lights. The wrong star ends the call.",
          [
            choice("Claim the red star", "It burns too steadily.", "death", "starfall-death"),
            choice("Claim the white star", "It pulses in time with the gate.", "victory", "wizard-victory"),
            choice("Claim the black star", "It swallows the lantern light.", "death", "void-death")
          ]
        ),
        terminal_choice_room(
          "wizard-victory",
          "Wizard's World Won",
          "victory",
          "The vault opens, the gate remembers your name, and the wizard lets you pass."
        ),
        terminal_choice_room("thorn-death", "Thorn Rune", "death", "The hedge grows inward. The line goes silent."),
        terminal_choice_room("ash-death", "Ash Rune", "death", "The gate exhales smoke and there is no next room."),
        terminal_choice_room("glass-death", "Laughing Mirror", "death", "The mirror keeps laughing after you are gone."),
        terminal_choice_room("echo-death", "Still Mirror", "death", "Your echo walks out. You do not."),
        terminal_choice_room("starfall-death", "Red Star", "death", "The red star falls through you like a hot nail."),
        terminal_choice_room("void-death", "Black Star", "death", "The black star answers with perfect silence.")
      ]
    end

    def home_body
      {
        "title" => "Private MUD Demo Home",
        "groups" => [
          {
            "title" => "Play",
            "links" => [
              view_link("Play Lantern House", "Start in the atrium.", document_key: "demo-world", schema_key: "mud-world"),
              view_link("Play Guest Explorer", "Play from the guest character location.", document_key: "guest", schema_key: "mud-character"),
              view_link("Play Atrium", "Open the atrium room directly.", document_key: "atrium", schema_key: "mud-room"),
              view_link("Wizard's World", "Three rooms, three choices each, one safe path.", document_key: "wizard-gate", schema_key: "mud-choice-room", view_title: "Choice Play")
            ]
          },
          {
            "title" => "Author",
            "links" => [
              schema_link("Rooms", "Author connected MUD rooms.", schema_key: "mud-room"),
              schema_link("Characters", "Author player characters and NPCs.", schema_key: "mud-character"),
              schema_link("Items", "Author room and inventory items.", schema_key: "mud-item"),
              schema_link("Worlds", "Author world start points.", schema_key: "mud-world"),
              schema_link("Choice Rooms", "Author three-choice PBX-style rooms.", schema_key: "mud-choice-room")
            ]
          }
        ]
      }
    end

    def room(key, title, zone, description, exits)
      {
        key: key,
        title: title,
        body: {
          "name" => title,
          "description" => description,
          "zone" => zone,
          "exits" => exits,
          "notes" => "Demo MUD room."
        }
      }
    end

    def exit_to(direction, room_key, label, description)
      {
        "direction" => direction,
        "label" => label,
        "room_key" => room_key,
        "description" => description
      }
    end

    def choice_room(key, title, room_type, stage, prompt, choices)
      {
        key: key,
        title: title,
        body: {
          "name" => title,
          "room_type" => room_type,
          "stage" => stage,
          "prompt" => prompt,
          "terminal_text" => "",
          "choices" => choices,
          "notes" => "Demo PBX-style choice room."
        }
      }
    end

    def terminal_choice_room(key, title, room_type, terminal_text)
      choice_room(key, title, room_type, "", terminal_text, []).tap do |definition|
        definition.fetch(:body)["terminal_text"] = terminal_text
      end
    end

    def choice(label, description, outcome, target_room_key)
      {
        "label" => label,
        "description" => description,
        "outcome" => outcome,
        "target_room_key" => target_room_key
      }
    end

    def schema_link(title, description, schema_key:)
      {
        "kind" => "schema",
        "title" => title,
        "description" => description,
        "schema_key" => schema_key
      }
    end

    def view_link(title, description, document_key:, schema_key:, view_title: "Play")
      {
        "kind" => "view",
        "title" => title,
        "description" => description,
        "document_key" => document_key,
        "schema_key" => schema_key,
        "view_title" => view_title
      }
    end
  end
end
