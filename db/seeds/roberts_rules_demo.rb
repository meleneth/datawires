# frozen_string_literal: true

module Seeds
  module RobertsRulesDemo
    module_function

    DOMAIN_ID = "1e3e4ce2-34c1-4ef3-b220-9fd454fb3a25"
    DOMAIN_NAME = "Robert's Rules Demo"
    MESSAGE = "Seed Robert's Rules demo"

    DOCUMENT_IDS = {
      "domain-home" => "20000000-0000-4000-8000-000000000001",
      "speaking-limits" => "20000000-0000-4000-8000-000000000101",
      "old-parking-policy" => "20000000-0000-4000-8000-000000000102",
      "motion-adopt-speaking-limits" => "20000000-0000-4000-8000-000000000201",
      "motion-amend-speaking-limits" => "20000000-0000-4000-8000-000000000202",
      "motion-close-old-parking-policy" => "20000000-0000-4000-8000-000000000203",
      "meeting-opens" => "20000000-0000-4000-8000-000000000301",
      "speaking-limits-introduced" => "20000000-0000-4000-8000-000000000302",
      "speaking-limits-adopted" => "20000000-0000-4000-8000-000000000303",
      "speaking-limits-amended" => "20000000-0000-4000-8000-000000000304",
      "old-parking-policy-closed" => "20000000-0000-4000-8000-000000000305",
      "meeting-adjourned" => "20000000-0000-4000-8000-000000000306",
      "current-meeting" => "20000000-0000-4000-8000-000000000401"
    }.freeze

    def seed!
      actor = User.find_or_create_by!(id: ApplicationController::DEV_USER_ID) do |user|
        user.name = "devUser"
        user.avatar = "https://api.dicebear.com/7.x/pixel-art/png?seed=devUser"
      end
      domain = ensure_domain!
      home_changed = ensure_home_document!(domain: domain)

      Clusters::SeedDomain.call(domain: domain, cluster_key: Clusters::Catalog::ROBERTS_RULES, actor: actor)

      schema_documents = domain.documents.where(key: %w[agreement motion proceeding-event meeting-state]).index_by(&:key)
      changed = home_changed

      agreements.each { |definition| changed |= ensure_document!(domain:, schema_documents:, schema_key: "agreement", definition:) }
      motions.each { |definition| changed |= ensure_document!(domain:, schema_documents:, schema_key: "motion", definition:) }
      proceeding_events.each { |definition| changed |= ensure_document!(domain:, schema_documents:, schema_key: "proceeding-event", definition:) }
      meeting_states.each { |definition| changed |= ensure_document!(domain:, schema_documents:, schema_key: "meeting-state", definition:) }

      DomainCommits::Create.call(domain: domain, message: MESSAGE, actor: actor) if changed
      domain
    end

    def ensure_domain!
      domain = Domain.find_or_initialize_by(id: DOMAIN_ID)
      domain.name = DOMAIN_NAME
      domain.repository_mode = true
      domain.save! if domain.new_record? || domain.changed?
      domain
    rescue ActiveRecord::RecordNotUnique, ActiveRecord::RecordInvalid
      Domain.find_by!(name: DOMAIN_NAME)
    end

    def ensure_home_document!(domain:)
      document = domain.documents.find_or_initialize_by(key: DomainHomeLinks::DOCUMENT_KEY)
      document.id = DOCUMENT_IDS.fetch(DomainHomeLinks::DOCUMENT_KEY) if document.new_record?
      document.title = "Domain Home"
      document.save! if document.new_record? || document.changed?

      body = Clusters::Catalog.definition_for(Clusters::Catalog::ROBERTS_RULES).fetch(:home)
      return false if document.body == body

      revision = document.revisions.create!(
        body: body,
        parent_revision: document.head_revision,
        message: MESSAGE
      )
      document.update!(head_revision: revision)
      true
    end

    def ensure_document!(domain:, schema_documents:, schema_key:, definition:)
      document = domain.documents.find_or_initialize_by(key: definition.fetch(:key))
      document.id = DOCUMENT_IDS.fetch(definition.fetch(:key)) if document.new_record?
      document.title = definition.fetch(:title)
      document.save! if document.new_record? || document.changed?

      changed = false
      body = definition.fetch(:body)
      if document.body != body
        revision = document.revisions.create!(
          body: body,
          parent_revision: document.head_revision,
          message: MESSAGE
        )
        document.update!(head_revision: revision)
        changed = true
      end

      schema_document = schema_documents.fetch(schema_key)
      document.update!(schema_document: schema_document) if document.schema_document != schema_document
      DocumentIndexes::Rebuild.call(document: document)
      changed
    end

    def agreements
      [
        agreement("speaking-limits", "Speaking limits", "amended", 30, "Members may speak twice for up to three minutes per motion."),
        agreement("old-parking-policy", "Old parking policy", "closed", -10, "Prior parking policy retained for archive reference only.")
      ]
    end

    def motions
      [
        motion(
          "motion-adopt-speaking-limits",
          "Adopt speaking limits",
          "main",
          "adopted",
          10,
          "speaking-limits",
          "",
          "Members may speak once for up to two minutes per motion.",
          "applied: speaking-limits"
        ),
        motion(
          "motion-amend-speaking-limits",
          "Amend speaking limits",
          "amend",
          "adopted",
          30,
          "",
          "speaking-limits",
          "Members may speak twice for up to three minutes per motion.",
          "applied: speaking-limits"
        ),
        motion(
          "motion-close-old-parking-policy",
          "Close old parking policy",
          "close",
          "adopted",
          45,
          "",
          "old-parking-policy",
          "Close the prior parking policy.",
          "applied: old-parking-policy"
        )
      ]
    end

    def proceeding_events
      [
        event("meeting-opens", 0, "start_meeting", "Meeting opens", "", "", "The chair calls the meeting to order."),
        event("speaking-limits-introduced", 10, "introduce_motion", "Speaking limits introduced", "motion-adopt-speaking-limits", "", "A main motion proposes limits for debate."),
        event("speaking-limits-adopted", 20, "vote", "Speaking limits adopted", "motion-adopt-speaking-limits", "speaking-limits", "The main motion is adopted."),
        event("speaking-limits-amended", 30, "amend_motion", "Speaking limits amended", "motion-amend-speaking-limits", "speaking-limits", "The agreement is amended after debate."),
        event("old-parking-policy-closed", 45, "vote", "Old parking policy closed", "motion-close-old-parking-policy", "old-parking-policy", "A stale agreement is closed."),
        event("meeting-adjourned", 60, "adjourn", "Meeting adjourned", "", "", "The chair adjourns the meeting.")
      ]
    end

    def meeting_states
      [
        {
          key: "current-meeting",
          title: "Current meeting",
          body: {
            "name" => "Demo board meeting",
            "phase" => "adjourned",
            "current_motion_key" => "",
            "current_agreement_key" => "speaking-limits",
            "notes" => "Seeded meeting state after the demo proceedings."
          }
        }
      ]
    end

    def agreement(key, title, status, relative_time, body)
      {
        key: key,
        title: title,
        body: {
          "title" => title,
          "status" => status,
          "body" => body,
          "relative_time" => relative_time,
          "supersedes_agreement_key" => "",
          "extends_agreement_key" => "",
          "notes" => "Demo agreement for Robert's Rules workflows."
        }
      }
    end

    def motion(key, title, motion_type, status, relative_time, new_agreement_key, target_agreement_key, proposed_text, result)
      {
        key: key,
        title: title,
        body: {
          "title" => title,
          "motion_type" => motion_type,
          "status" => status,
          "relative_time" => relative_time,
          "new_agreement_key" => new_agreement_key,
          "target_agreement_key" => target_agreement_key,
          "proposed_text" => proposed_text,
          "mover_key" => "member-a",
          "seconder_key" => "member-b",
          "result" => result,
          "notes" => "Demo motion with an applied result."
        }
      }
    end

    def event(key, relative_time, event_type, title, motion_key, agreement_key, summary)
      {
        key: key,
        title: title,
        body: {
          "relative_time" => relative_time,
          "event_type" => event_type,
          "title" => title,
          "motion_key" => motion_key,
          "agreement_key" => agreement_key,
          "summary" => summary,
          "notes" => "Demo proceeding event."
        }
      }
    end
  end
end
