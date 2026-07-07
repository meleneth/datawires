# frozen_string_literal: true

module ViewAffordances
  Projection = Data.define(:renderer, :title, :data) do
    def self.build(document:, view_affordance:)
      body = view_affordance.body
      renderer = body["renderer"].to_s

      case renderer
      when "timeline_d3"
        TimelineD3Projection.call(document:, view_affordance:)
      when "mud_player"
        MudPlayerProjection.call(document:, view_affordance:)
      when "mud_choice_player"
        MudChoicePlayerProjection.call(document:, view_affordance:)
      else
        new(
          renderer: "unsupported",
          title: body["title"].presence || view_affordance.title,
          data: {
            "message" => "Unsupported view renderer",
            "renderer" => renderer.presence || "(blank)"
          }
        )
      end
    end
  end
end
