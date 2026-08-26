# frozen_string_literal: true

require Rails.root.join("app/lib/datawires/provider_registry")

Rails.application.config.to_prepare do
  Datawires::Providers.cards.register("document", "Boards::Cards::DocumentProvider")
  Datawires::Providers.cards.register("action", "Boards::Cards::ActionProvider")
  Datawires::Providers.cards.register("form", "Boards::Cards::FormProvider")
  Datawires::Providers.layouts.register("kanban", "Boards::Layouts::KanbanProvider")
  Datawires::Providers.layouts.register("grid", "Boards::Layouts::GridProvider")
  Datawires::Providers.layouts.register("list", "Boards::Layouts::ListProvider")
  Datawires::Providers.sources.register("http_json", "Sources::Adapters::HttpJson")
end
