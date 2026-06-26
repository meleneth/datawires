# frozen_string_literal: true

module Seeds
  module WorldbuilderDemo
    module_function

    DOMAIN_ID = "0e3e4ce2-34c1-4ef3-b220-9fd454fb3a25"
    DOMAIN_NAME = "Worldbuilder Demo"
    MESSAGE = "Seed worldbuilder demo"

    DOCUMENT_IDS = {
      "frodo" => "10000000-0000-4000-8000-000000000001",
      "sam" => "10000000-0000-4000-8000-000000000002",
      "aragorn" => "10000000-0000-4000-8000-000000000003",
      "gandalf" => "10000000-0000-4000-8000-000000000004",
      "boromir" => "10000000-0000-4000-8000-000000000005",
      "legolas" => "10000000-0000-4000-8000-000000000006",
      "gimli" => "10000000-0000-4000-8000-000000000007",
      "merry" => "10000000-0000-4000-8000-000000000008",
      "pippin" => "10000000-0000-4000-8000-000000000009",
      "the-shire" => "10000000-0000-4000-8000-000000000101",
      "rivendell" => "10000000-0000-4000-8000-000000000102",
      "moria" => "10000000-0000-4000-8000-000000000103",
      "lothlorien" => "10000000-0000-4000-8000-000000000104",
      "amon-hen" => "10000000-0000-4000-8000-000000000105",
      "fellowship" => "10000000-0000-4000-8000-000000000201",
      "hobbit-party" => "10000000-0000-4000-8000-000000000202",
      "council-rivendell" => "10000000-0000-4000-8000-000000000301",
      "fellowship-forms" => "10000000-0000-4000-8000-000000000302",
      "fellowship-departs" => "10000000-0000-4000-8000-000000000303",
      "gandalf-parts-moria" => "10000000-0000-4000-8000-000000000304",
      "lorien-rest" => "10000000-0000-4000-8000-000000000305",
      "boromir-parts" => "10000000-0000-4000-8000-000000000306",
      "fellowship-breaks" => "10000000-0000-4000-8000-000000000307"
    }.freeze

    def seed!
      actor = User.find_or_create_by!(id: ApplicationController::DEV_USER_ID) do |user|
        user.name = "devUser"
        user.avatar = "https://api.dicebear.com/7.x/pixel-art/png?seed=devUser"
      end
      domain = ensure_domain!

      Clusters::SeedDomain.call(domain: domain, cluster_key: Clusters::Catalog::WORLD_BUILDING, actor: actor)

      schema_documents = domain.documents.where(key: %w[person place party timeline-event]).index_by(&:key)

      people.each { |definition| ensure_document!(domain:, schema_documents:, schema_key: "person", definition:) }
      places.each { |definition| ensure_document!(domain:, schema_documents:, schema_key: "place", definition:) }
      parties.each { |definition| ensure_document!(domain:, schema_documents:, schema_key: "party", definition:) }
      timeline_events.each { |definition| ensure_document!(domain:, schema_documents:, schema_key: "timeline-event", definition:) }
      DocumentIndexes::RebuildTimelineDomain.call(domain: domain)

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

    def people
      [
        person("frodo", "Frodo Baggins", "Ring-bearer from the Shire."),
        person("sam", "Samwise Gamgee", "Frodo's companion from the Shire."),
        person("aragorn", "Aragorn", "Ranger and heir connected to Gondor."),
        person("gandalf", "Gandalf", "Wizard who guides the company."),
        person("boromir", "Boromir", "Representative of Gondor."),
        person("legolas", "Legolas", "Elf of the Woodland Realm."),
        person("gimli", "Gimli", "Dwarf of the Lonely Mountain's people."),
        person("merry", "Meriadoc Brandybuck", "Hobbit companion from the Shire."),
        person("pippin", "Peregrin Took", "Hobbit companion from the Shire.")
      ]
    end

    def places
      [
        place("the-shire", "The Shire", "region", "Home region of the hobbits."),
        place("rivendell", "Rivendell", "refuge", "Elven refuge where the council is held."),
        place("moria", "Moria", "underground realm", "Ancient dwarf realm crossed by the company."),
        place("lothlorien", "Lothlorien", "forest realm", "Elven forest realm visited after Moria."),
        place("amon-hen", "Amon Hen", "ruin", "Site where the company breaks apart.")
      ]
    end

    def parties
      [
        {
          key: "fellowship",
          title: "Fellowship of the Ring",
          body: {
            "name" => "Fellowship of the Ring",
            "summary" => "Company formed to accompany the Ring-bearer.",
            "members" => %w[frodo sam aragorn gandalf boromir legolas gimli merry pippin].map do |person_key|
              { "person_key" => person_key, "role" => "member", "notes" => "Initial company member." }
            end,
            "notes" => "Demo party for timeline membership events."
          }
        },
        {
          key: "hobbit-party",
          title: "Hobbit companions",
          body: {
            "name" => "Hobbit companions",
            "summary" => "The hobbits traveling together before the larger company forms.",
            "members" => %w[frodo sam merry pippin].map do |person_key|
              { "person_key" => person_key, "role" => "traveler", "notes" => "Travels from the Shire toward Rivendell." }
            end,
            "notes" => "Smaller party used to demonstrate party-to-party timeline participation."
          }
        }
      ]
    end

    def timeline_events
      [
        event(
          "council-rivendell",
          -30,
          "general",
          "Council at Rivendell",
          "The major parties gather at Rivendell and decide the Ring's course.",
          participants: [
            participant("person", "frodo", "ring-bearer"),
            participant("person", "aragorn", "council participant"),
            participant("person", "gandalf", "council participant"),
            participant("party", "hobbit-party", "represented group")
          ],
          notes: "Relative date is approximate for demo purposes."
        ),
        event(
          "fellowship-forms",
          0,
          "party_join",
          "Fellowship forms",
          "The nine-member company is established at Rivendell.",
          participants: [
            participant("party", "fellowship", "new party"),
            participant("person", "frodo", "joins"),
            participant("person", "sam", "joins"),
            participant("person", "aragorn", "joins"),
            participant("person", "gandalf", "joins"),
            participant("person", "boromir", "joins"),
            participant("person", "legolas", "joins"),
            participant("person", "gimli", "joins"),
            participant("person", "merry", "joins"),
            participant("person", "pippin", "joins")
          ],
          party_key: "fellowship",
          person_key: "frodo",
          notes: "The event records the party and representative join participants."
        ),
        event(
          "fellowship-departs",
          12,
          "general",
          "Fellowship leaves Rivendell",
          "The company departs Rivendell and begins the southward journey.",
          participants: [
            participant("party", "fellowship", "traveling party"),
            participant("person", "gandalf", "guide")
          ],
          notes: "A travel event with party-level participation."
        ),
        event(
          "gandalf-parts-moria",
          95,
          "party_leave",
          "Gandalf parts from the company in Moria",
          "The company loses Gandalf during the crossing of Moria.",
          participants: [
            participant("party", "fellowship", "affected party"),
            participant("person", "gandalf", "leaves")
          ],
          party_key: "fellowship",
          person_key: "gandalf",
          notes: "Party leave event represented with relative time."
        ),
        event(
          "lorien-rest",
          105,
          "general",
          "Company rests in Lothlorien",
          "The remaining company reaches Lothlorien after Moria.",
          participants: [
            participant("party", "fellowship", "remaining company"),
            participant("person", "aragorn", "leader")
          ],
          notes: "Clustered near the Moria event to exercise timeline density."
        ),
        event(
          "boromir-parts",
          150,
          "party_leave",
          "Boromir parts from the company",
          "Boromir's path separates from the Fellowship at Amon Hen.",
          participants: [
            participant("party", "fellowship", "affected party"),
            participant("person", "boromir", "leaves")
          ],
          party_key: "fellowship",
          person_key: "boromir",
          notes: "A second leave event for the same party."
        ),
        event(
          "fellowship-breaks",
          152,
          "general",
          "Fellowship breaks apart",
          "The surviving members split into separate paths after Amon Hen.",
          participants: [
            participant("party", "fellowship", "splits"),
            participant("person", "frodo", "continues separately"),
            participant("person", "sam", "continues with Frodo"),
            participant("person", "aragorn", "leads pursuit")
          ],
          notes: "Close to the Boromir event to demonstrate tightly clustered times."
        )
      ]
    end

    def person(key, name, summary)
      {
        key: key,
        title: name,
        body: {
          "name" => name,
          "summary" => summary,
          "origin" => "",
          "notes" => "Demo data for worldbuilding affordances."
        }
      }
    end

    def place(key, name, kind, summary)
      {
        key: key,
        title: name,
        body: {
          "name" => name,
          "kind" => kind,
          "summary" => summary,
          "notes" => "Demo place for timeline mapping."
        }
      }
    end

    def participant(kind, key, role)
      {
        "kind" => kind,
        "key" => key,
        "role" => role,
        "notes" => role.humanize
      }
    end

    def event(key, relative_time, event_type, title, summary, participants:, notes:, party_key: "", person_key: "")
      {
        key: key,
        title: title,
        body: {
          "relative_time" => relative_time,
          "title" => title,
          "event_type" => event_type,
          "summary" => summary,
          "participants" => participants,
          "party_key" => party_key,
          "person_key" => person_key,
          "notes" => notes
        }
      }
    end
  end
end
