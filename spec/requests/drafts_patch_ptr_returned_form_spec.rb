# frozen_string_literal: true

require "rails_helper"
require "nokogiri"

RSpec.describe "Drafts patch_ptr returned form loop", type: :request do
  let(:schema_document) do
    create(:document, :with_name_schema)
  end

  let(:document) do
    create(
      :document,
      :conforming_to_schema,
      :with_head_revision,
      schema_document_record: schema_document,
      head_body: {}
    )
  end

  let(:draft) do
    create(
      :draft,
      document: document,
      based_on_revision: document.head_revision,
      body: {}
    )
  end

  let(:name_affordance) do
    {
      "version" => 1,
      "rows" => [
        [
          {
            "ptr" => "/name",
            "label" => "Name",
            "widget" => "text"
          }
        ]
      ]
    }
  end

  before do
    allow_any_instance_of(DraftsController)
      .to receive(:selected_edit_affordance_body)
      .and_return(name_affordance)
  end

  def turbo_stream_fragment_for(response_body, target:)
    doc = Nokogiri::XML::DocumentFragment.parse(response_body)

    stream = doc.at_css(%(turbo-stream[target="#{target}"]))
    expect(stream).to be_present

    template = stream.at_css("template")
    expect(template).to be_present

    Nokogiri::HTML5.fragment(template.inner_html)
  end

  def extract_form_from_turbo_stream(response_body, target:)
    fragment = turbo_stream_fragment_for(response_body, target: target)
    form = fragment.at_css("form")
    expect(form).to be_present
    form
  end

  def params_from_form(form)
    params = {}

    form.css("input, textarea, select").each do |field|
      name = field["name"]
      next if name.blank?
      next if field["disabled"]

      case field.name
      when "input"
        type = (field["type"] || "text").downcase

        case type
        when "submit", "button", "file", "image", "reset"
          next
        when "checkbox", "radio"
          next unless field["checked"]
          params[name] = field["value"]
        else
          params[name] = field["value"].to_s
        end
      when "textarea"
        params[name] = field.text
      when "select"
        selected = field.at_css("option[selected]") || field.at_css("option")
        params[name] = selected ? selected["value"].to_s : ""
      end
    end

    params
  end

  def patch_method_for_form(form)
    method_override = form.at_css('input[name="_method"]')&.[]("value")&.downcase
    (method_override.presence || form["method"].presence || "post").downcase
  end

  it "can submit the form returned by the first patch response" do
    patch patch_ptr_draft_path(draft),
          params: { ptr: "/name", value: "Alice" },
          as: :turbo_stream

    expect(response).to have_http_status(:ok)
    expect(draft.reload.body).to eq("name" => "Alice")

    returned_form = extract_form_from_turbo_stream(response.body, target: "editor")

    expect(returned_form["action"]).to eq(patch_ptr_draft_path(draft))
    expect(patch_method_for_form(returned_form)).to eq("patch")

    returned_params = params_from_form(returned_form)
    expect(returned_params["ptr"]).to eq("/name")
    expect(returned_params["value"]).to eq("Alice")

    returned_params["value"] = "Beatrice"

    patch returned_form["action"],
          params: returned_params,
          as: :turbo_stream

    expect(response).to have_http_status(:ok)
    expect(draft.reload.body).to eq("name" => "Beatrice")
  end
end
