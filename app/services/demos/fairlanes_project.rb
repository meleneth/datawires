# frozen_string_literal: true

module Demos
  class FairlanesProject
    DOMAIN_NAME = "Fairlanes Showcase"
    SOURCE_KEY = "fairlanes-demo-telemetry"

    def self.call(actor:)
      new(actor:).call
    end

    def initialize(actor:)
      @actor = actor
    end

    def call
      ApplicationRecord.transaction do
        domain = Domain.find_or_initialize_by(name: DOMAIN_NAME)
        domain.assign_attributes(owner: actor, public: true)
        domain.save!
        project = Projects::Install.call(domain:, actor:, title: "Fairlanes",
          description: "Autobattler production workspace: combat telemetry, content balance, and strange moons.")
        schema = ensure_note_schema(domain)
        notes.each { |key, note| publish_note(domain:, schema:, key:, **note) }
        source = ensure_source(domain)
        ensure_observations(source)
        ensure_metric(domain, key: "encounters-per-hour", title: "Encounters per hour", unit: "encounters/hour",
          aggregation: "average")
        ensure_metric(domain, key: "party-survival-rate", title: "Party survival rate", unit: "%",
          aggregation: "average")
        ensure_query(domain, key: "encounter-throughput", title: "Encounter throughput",
          metric_key: "encounters-per-hour")
        ensure_query(domain, key: "survival-trend", title: "Survival trend", metric_key: "party-survival-rate")
        project.update!(default_board: ensure_board(project))
        domain
      end
    end

    private

    attr_reader :actor

    def ensure_note_schema(domain)
      body = {
        "$schema" => Document::JSON_SCHEMA_2020_12, "title" => "Fairlanes Project Note", "type" => "object",
        "required" => %w[title summary status bullets],
        "properties" => {
          "title" => { "type" => "string" }, "summary" => { "type" => "string" },
          "status" => { "enum" => %w[active stable planned research] },
          "bullets" => { "type" => "array", "items" => { "type" => "string" } }
        }, "additionalProperties" => false
      }
      publish_document(domain:, key: "fairlanes-project-note", title: "Fairlanes Project Note", body:).tap do |document|
        SyncSchemaWrapperForDocument.call(document:)
      end
    end

    def publish_note(domain:, schema:, key:, title:, summary:, status:, bullets:)
      publish_document(domain:, key:, title:, schema_document: schema,
        body: { "title" => title, "summary" => summary, "status" => status, "bullets" => bullets })
    end

    def publish_document(domain:, key:, title:, body:, schema_document: nil)
      document = domain.documents.find_or_initialize_by(key:)
      document.assign_attributes(title:, schema_document:)
      document.save! if document.new_record? || document.changed?
      return document if document.body == body

      revision = document.revisions.create!(body:, parent_revision: document.head_revision,
        message: "Refresh Fairlanes showcase", created_by: actor)
      document.update!(head_revision: revision)
      document
    end

    def ensure_source(domain)
      source = domain.sources.includes(source_document: :head_revision).find do |candidate|
        candidate.source_document.key == SOURCE_KEY
      end
      return source if source

      source = Sources::Create.call(domain:, actor:, title: "Fairlanes simulation telemetry", adapter: "http_json",
        config: { "url" => "https://fairlanes.deva.station/api/telemetry", "method" => "GET" },
        observation: { "type" => "simulation_metric", "metric_key" => "encounters-per-hour",
          "value_pointer" => "/value", "unit" => "encounters/hour" })
      source.source_document.update!(key: SOURCE_KEY)
      source
    end

    def ensure_observations(source)
      return if source.source_runs.exists?(idempotency_key: "fairlanes-showcase-v1")

      run = source.source_runs.create!(configuration_revision: source.head_revision, triggered_by: actor,
        trigger: "manual", adapter: "http_json", adapter_version: "1", idempotency_key: "fairlanes-showcase-v1",
        status: "succeeded", started_at: 14.days.ago, finished_at: Time.current, observation_count: 28,
        metadata: { "fixture" => "Fairlanes generated content and simulated battle telemetry" })
      encounter_values = [ 31, 34, 33, 38, 42, 45, 43, 49, 52, 55, 58, 61, 64, 69 ]
      survival_values = [ 62, 64, 67, 66, 70, 72, 74, 73, 77, 79, 81, 83, 86, 88 ]
      encounter_values.each_with_index do |value, index|
        observed_at = (13 - index).days.ago.beginning_of_hour
        append_observation(source:, run:, metric_key: "encounters-per-hour", unit: "encounters/hour", value:, observed_at:)
        append_observation(source:, run:, metric_key: "party-survival-rate", unit: "%",
          value: survival_values.fetch(index), observed_at:)
      end
      source.update!(status: "succeeded", last_started_at: run.started_at, last_succeeded_at: run.finished_at)
    end

    def append_observation(source:, run:, metric_key:, unit:, value:, observed_at:)
      source.observations.create!(domain: source.domain, source_run: run, configuration_revision: source.head_revision,
        observation_type: "simulation_metric", metric_key:, unit:, numeric_value: value,
        dimensions: { "build" => "linux-debug", "scenario" => "woodland" }, payload: { "value" => value },
        observed_at:, effective_at: observed_at, recorded_at: Time.current,
        provenance: { "source_id" => source.id, "source_document_id" => source.source_document_id,
          "configuration_revision_id" => source.head_revision.id, "source_run_id" => run.id,
          "adapter" => run.adapter, "adapter_version" => run.adapter_version })
    end

    def ensure_metric(domain, key:, title:, unit:, aggregation:)
      return domain.metric_definitions.find_by(key:) if domain.metric_definitions.exists?(key:)

      VersionedDefinitions::Create.call(domain:, actor:, schema: Metrics::Schema, key:, title:,
        wrapper_class: MetricDefinition, document_association: :metric_document,
        body: { "version" => 1, "key" => key, "title" => title, "value_type" => "number", "unit" => unit,
          "dimensions" => %w[build scenario], "aggregation" => aggregation, "correction_policy" => "latest" })
    end

    def ensure_query(domain, key:, title:, metric_key:)
      return domain.query_definitions.find_by(key:) if domain.query_definitions.exists?(key:)

      VersionedDefinitions::Create.call(domain:, actor:, schema: Queries::Schema, key:, title:,
        wrapper_class: QueryDefinition, document_association: :query_document,
        body: { "version" => 1, "key" => key, "title" => title, "metric_key" => metric_key,
          "bucket_seconds" => 86_400, "aggregate" => "average" })
    end

    def ensure_board(project)
      existing = project.project_document.schema_document.schema_wrapper.boards.find_by(title: "Fairlanes Command Deck")
      if existing
        if existing.body != board_definition
          revision = existing.board_document.revisions.create!(body: board_definition, parent_revision: existing.head_revision,
            message: "Refresh Fairlanes command deck", created_by: actor)
          existing.board_document.update!(head_revision: revision)
        end
        return existing
      end

      CreateBoard.call(schema_wrapper: project.project_document.schema_document.schema_wrapper,
        title: "Fairlanes Command Deck", actor:, definition: board_definition).board
    end

    def board_definition
      {
        "version" => 1, "title" => "Fairlanes Command Deck",
        "description" => "One day, a Field Mouse thumped me. Now we measure the consequences.",
        "layout" => { "provider" => "grid", "columns" => 3 },
        "columns" => [
          { "id" => "now", "title" => "Now", "cards" => [
            document_card("brief", "Project brief", "fairlanes-project-brief"),
            image_card("runtime-overview", "Executable: battle overview", "/demo/fairlanes/runtime-overview.png",
              "Fairlanes FTXUI multi-party battle overview",
              "Local build-linux-debug executable: moon cycles, combatants, ATB, scoped logs, deaths, and learned skills."),
            metric_card("throughput", "Latest encounter throughput", "encounters-per-hour"),
            graph_card("throughput-trend", "14-day encounter throughput", "encounters-per-hour", "line")
          ] },
          { "id" => "systems", "title" => "Game systems", "cards" => [
            document_card("combat", "Combat spine", "fairlanes-combat-spine"),
            image_card("party-detail", "Executable: party detail", "/demo/fairlanes/runtime-screen-2.png",
              "Fairlanes FTXUI focused party view",
              "Focused party projection with inventory, equipment, learned skills, HP/ATB state, and status-effect logs."),
            document_card("skills-effects", "Skills, effects, buffs & debuffs", "fairlanes-skills-effects"),
            document_card("content", "Content balance", "fairlanes-content-balance"),
            graph_card("survival", "Party survival trend", "party-survival-rate", "area")
          ] },
          { "id" => "next", "title" => "Next", "cards" => [
            document_card("roadmap", "Roadmap", "fairlanes-roadmap"),
            image_card("all-accounts", "Executable: all-account combat", "/demo/fairlanes/runtime-screen-3.png",
              "Fairlanes FTXUI all-account combat view",
              "Eight concurrent account/party projections exercising attacks, healing, poison, bleed, frost, and skill learning."),
            document_card("cycles", "The Three Cycles", "fairlanes-three-cycles"),
            { "id" => "stats", "kind" => "query", "title" => "Encounter statistics",
              "description" => "Daily buckets with exact source revision lineage.",
              "config" => { "query_key" => "encounter-throughput" } }
          ] }
        ], "sections" => [], "actions" => []
      }
    end

    def document_card(id, title, key)
      { "id" => id, "kind" => "document", "title" => title, "config" => { "document_key" => key } }
    end

    def metric_card(id, title, metric_key)
      { "id" => id, "kind" => "metric", "title" => title, "config" => { "metric_key" => metric_key, "statistic" => "last" } }
    end

    def image_card(id, title, src, alt, caption)
      { "id" => id, "kind" => "image", "title" => title, "config" => { "src" => src, "alt" => alt, "caption" => caption } }
    end

    def graph_card(id, title, metric_key, renderer)
      { "id" => id, "kind" => "graph", "title" => title,
        "config" => { "metric_key" => metric_key, "bucket_seconds" => 86_400, "aggregate" => "average", "renderer" => renderer } }
    end

    def notes
      {
        "fairlanes-project-brief" => { title: "Fairlanes: automated adventure operations", status: "active",
          summary: "A C++20 terminal autobattler where parties farm, fight, recover, gear up, and learn from monsters.",
          bullets: [ "8 autonomous accounts", "EnTT ECS + SML state machines + eventpp buses", "FTXUI battle and account views",
            "Core loop: explore → fight → loot/XP → town → recover → repeat" ] },
        "fairlanes-combat-spine" => { title: "Combat spine", status: "stable",
          summary: "Only one combatant is active at a time; timed intent flows through narrow event and context boundaries.",
          bullets: [ "Beat → PartyTick → ATB → BecameActive", "SkillSequencer schedules visuals, damage, status work, and FinishedTurn",
            "Poison, Freeze, and Dire Bleed clean up on death and combat exit", "Party-, account-, and entity-scoped contexts preserve authority and logs" ] },
        "fairlanes-content-balance" => { title: "Generated content balance", status: "active",
          summary: "Ruby-authored declarations generate reviewed C++ runtime tables and topology reports.",
          bullets: [ "69 skill definitions", "71 monster declarations", "69 common and 2 rare woodland monsters",
            "Progression runs from Field Mouse (5 HP) to Null Kraken (430 HP)", "Starfire Anomaly brings Starblaze, Flame Wave, and Gravity Sigh" ] },
        "fairlanes-skills-effects" => { title: "Skills, effects, buffs & debuffs", status: "active",
          summary: "The generated declaration set separates shipped runtime behavior from explicitly visible placeholders.",
          bullets: [ "69 skills: Observe/Flee plus direct, group, healing, status, and decal-driven behaviors",
            "Handwritten behaviors: Thump, Eviscerate, Poison, Cold Snap, Flame Strike, Flame Wave, Observe, and Flee",
            "Generated damage: Joltspasm, Rocks Fall, Blood Bloom, Ice Splitter, Gravity Sigh, Starblaze, and 30+ strike/group skills",
            "Healing/cleanse: Mercyburst, Mercywave, Field Dressing, Reboot Pulse, and Clearbell",
            "Implemented debuffs: Poison, Frozen/Cold Snap, and Dire Bleed with lifecycle cleanup",
            "Declared buffs/wards: Cinder Veil, Rime Armor, Overcharge, Choirguard, Clock Up, Pack Howl, Shell Guard, Battle Focus, Armor Plate, and Checksum Ward",
            "Declared control/debuff effects: Whiteout, Hush Hex, Miasma Cloud, Weight of Tuesday, Smoke Screen, Signal Jam, Blue Screen, Web Snare, Gnat Cloud, and Signal Flare",
            "10 visual projections: FlameWave, Shock, RocksFall, PoisonCloud, HolyNova, BloodBloom, FrostCrack, VoidRipple, Starfire, and Observe" ] },
        "fairlanes-roadmap" => { title: "Roadmap", status: "planned",
          summary: "Turn the simulation into a legible, surprising world without moving authority into presentation code.",
          bullets: [ "Promote placeholder effects into runtime behavior", "Balance skill observation and learning probabilities",
            "Expand loot, gear maintenance, and festival events", "Profile battle rendering under high entity counts" ] },
        "fairlanes-three-cycles" => { title: "The Three Cycles", status: "research",
          summary: "Two moons and a comet make a calendar that historians fear and geologists drink about.",
          bullets: [ "The Runner: jagged 9-day moon; bold predators and thin sleep", "The Elder: 21-day civic moon governing crops, travel, taxes, and festivals",
            "Split-Light every 63 days reveals mirrored iron", "Twin Dark every 189 days makes the ocean wrong",
            "The Visitor returns every 1,323 days and turns astronomy into civilization-scale catastrophe" ] }
      }
    end
  end
end
