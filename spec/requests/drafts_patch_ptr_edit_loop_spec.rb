# frozen_string_literal: true

require "rails_helper"
require "nokogiri"

RSpec.describe "Drafts patch_ptr turbo stream response", type: :request do
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

  it "rerenders a usable editor form after patching" do
    patch patch_ptr_draft_path(draft),
          params: { ptr: "/name", value: "Alice" },
          as: :turbo_stream

    expect(response).to have_http_status(:ok)
    expect(draft.reload.body).to eq("name" => "Alice")

    fragment = turbo_stream_fragment_for(response.body, target: "editor")

    form = fragment.at_css("form")
    expect(form).to be_present

    hidden_ptr = form.at_css('input[type="hidden"][name="ptr"]')
    expect(hidden_ptr).to be_present
    expect(hidden_ptr["value"]).to eq("/name")

    value_input = form.at_css('input[name="value"]')
    expect(value_input).to be_present
    expect(value_input["value"]).to eq("Alice")

    expect(form["action"]).to eq(patch_ptr_draft_path(draft))
    expect(form["method"]).to satisfy { |m| m == "post" || m == "patch" || m.blank? }

    method_override = form.at_css('input[name="_method"]')
    if method_override
      expect(method_override["value"]).to eq("patch")
    end

    expect(form["data-controller"]).to include("autosave")
  end

  it "rerenders a still-usable form after patching twice" do
    patch patch_ptr_draft_path(draft),
          params: { ptr: "/name", value: "Alice" },
          as: :turbo_stream

    expect(response).to have_http_status(:ok)

    first_fragment = turbo_stream_fragment_for(response.body, target: "editor")
    first_form = first_fragment.at_css("form")
    expect(first_form).to be_present
    expect(first_form.at_css('input[type="hidden"][name="ptr"]')["value"]).to eq("/name")
    expect(first_form.at_css('input[name="value"]')["value"]).to eq("Alice")

    patch patch_ptr_draft_path(draft),
          params: { ptr: "/name", value: "Beatrice" },
          as: :turbo_stream

    expect(response).to have_http_status(:ok)
    expect(draft.reload.body).to eq("name" => "Beatrice")

    second_fragment = turbo_stream_fragment_for(response.body, target: "editor")
    second_form = second_fragment.at_css("form")
    expect(second_form).to be_present
    expect(second_form.at_css('input[type="hidden"][name="ptr"]')["value"]).to eq("/name")
    expect(second_form.at_css('input[name="value"]')["value"]).to eq("Beatrice")
    expect(second_form["data-controller"]).to include("autosave")
  end
end
