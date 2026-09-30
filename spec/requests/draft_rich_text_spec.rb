# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Rich text draft fields", type: :request do
  let(:schema_document) do
    create(:document, :with_schema_head_revision, head_body: {
      "$schema" => Document::JSON_SCHEMA_2020_12,
      "type" => "object",
      "properties" => {
        "body" => { "type" => "string", "contentMediaType" => "text/html", "title" => "Article" },
        "source" => { "type" => "string" }
      }
    })
  end
  let(:schema_wrapper) { create(:schema_wrapper, document: schema_document) }
  let(:document) { create(:document, domain: schema_wrapper.domain, schema_document: schema_document) }
  let(:content) { '<p>Hello <strong>world</strong></p><ul><li>A list</li></ul>' }
  let(:draft) { create(:draft, document: document, body: { "body" => content, "source" => "<literal>" }) }

  def affordance_for(widget:, readonly: false)
    edit_document = create(:document, :with_head_revision, domain: schema_wrapper.domain, head_body: {
      "version" => 1,
      "rows" => [ [ {
        "binding" => { "kind" => "document_ptr", "ptr" => "/body" },
        "widget" => widget,
        "placeholder" => "Write an article",
        "display" => { "readonly" => readonly }
      } ] ]
    })
    create(:edit_affordance, schema_wrapper: schema_wrapper, edit_document: edit_document)
  end

  it "infers Lexxy for HTML strings and keeps ordinary strings as plain text" do
    get draft_path(draft)

    expect(response).to have_http_status(:ok)
    html = Nokogiri::HTML(response.body)
    editor = html.at_css("lexxy-editor#field_body")
    expect(editor["name"]).to eq("value")
    expect(editor["value"]).to eq(content)
    expect(editor["attachments"]).to eq("false")
    expect(editor["aria-label"]).to eq("Article")
    expect(editor["data-action"]).to eq("lexxy:change->autosave#queue lexxy:blur->autosave#submit")
    expect(editor.ancestors("form").first.at_css('input[name="ptr"]')["value"]).to eq("/body")
    expect(html.at_css("input#field_source")["value"]).to eq("<literal>")
  end

  it "supports explicit rich text widgets and plain text overrides" do
    affordance = affordance_for(widget: "rich_text")
    get draft_path(draft, edit_affordance_id: affordance.id)

    expect(response).to have_http_status(:ok)
    expect(Nokogiri::HTML(response.body).at_css("lexxy-editor")["placeholder"]).to eq("Write an article")

    plain_affordance = affordance_for(widget: "textarea")
    get draft_path(draft, edit_affordance_id: plain_affordance.id)

    html = Nokogiri::HTML(response.body)
    expect(html.at_css("lexxy-editor")).to be_nil
    expect(html.at_css("textarea#field_body").text.delete_prefix("\n")).to eq(content)
  end

  it "round trips formatted HTML through autosave and publishing as a JSON string" do
    patch patch_ptr_draft_path(draft), params: { ptr: "/body", value: content },
      headers: { "ACCEPT" => "text/vnd.turbo-stream.html" }

    expect(response).to have_http_status(:no_content)
    expect(draft.reload.body["body"]).to eq(content)

    post draft_commit_path(draft), params: { commit: { message: "Publish article" } }

    expect(response).to redirect_to(document_path(document))
    expect(document.reload.body).to eq("body" => content, "source" => "<literal>")
  end

  it "sanitizes read-only rich text while retaining formatting" do
    draft.update!(body: { "body" => '<p onclick="alert(1)"><strong>Safe</strong><script>alert(1)</script><a href="javascript:alert(1)">Link</a></p>' })
    affordance = affordance_for(widget: "rich_text", readonly: true)

    get draft_path(draft, edit_affordance_id: affordance.id)

    html = Nokogiri::HTML(response.body)
    preview = html.at_css("#field_body .lexxy-content")
    expect(preview.at_css("strong").text).to eq("Safe")
    expect(preview.css("script, [onclick], [href]")).to be_empty
    expect(html.at_css("lexxy-editor")).to be_nil
  end
end
