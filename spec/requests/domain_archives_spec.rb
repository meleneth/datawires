# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Domain archives", type: :request do
  it "downloads a portable domain archive" do
    domain = create(:domain, name: "Board Archive")
    Clusters::SeedDomain.call(domain: domain, cluster_key: Clusters::Catalog::ROBERTS_RULES, actor: nil)

    get domain_archive_path(domain)

    expect(response).to have_http_status(:ok)
    expect(response.media_type).to eq("application/json")
    expect(response.headers["Content-Disposition"]).to include("board-archive-archive.json")
    expect(response.body).not_to match(uuid_pattern)

    archive = JSON.parse(response.body)
    expect(archive).to include(
      "format" => DomainExports::Export::FORMAT,
      "version" => DomainExports::Export::VERSION
    )
    expect(archive.dig("domain", "name")).to eq("Board Archive")
    expect(archive.dig("domain", "head_domain_commit_ref")).to be_present
  end

  it "imports an uploaded domain archive" do
    source = create(:domain, name: "Source Archive")
    Clusters::SeedDomain.call(domain: source, cluster_key: Clusters::Catalog::ROBERTS_RULES, actor: nil)
    archive = DomainExports::Export.call(domain: source)

    expect {
      post domain_archives_path, params: {
        name: "Imported Archive",
        archive_file: uploaded_archive(archive)
      }
    }.to change(Domain, :count).by(1)

    imported = Domain.find_by!(name: "Imported Archive")
    expect(response).to redirect_to(domain_path(imported))
    expect(imported).to be_repository_mode
    expect(imported.head_domain_commit.state_hash).to eq(source.head_domain_commit.state_hash)
    expect(imported.documents.find_by!(key: "agreement")).to be_present
    expect(imported.documents.find_by!(key: "domain-home").schema_document.key).to eq("domain-home-page")
  end

  it "redirects with an alert when the uploaded archive is invalid" do
    expect {
      post domain_archives_path, params: {
        archive_file: uploaded_archive_text("not json")
      }
    }.not_to change(Domain, :count)

    expect(response).to redirect_to(domains_path)
    follow_redirect!
    expect(response.body).to include("Domain archive could not be imported")
  end

  def uploaded_archive(archive)
    uploaded_archive_text(JSON.generate(archive))
  end

  def uploaded_archive_text(contents)
    file = Tempfile.new([ "domain-archive", ".json" ])
    file.write(contents)
    file.rewind
    Rack::Test::UploadedFile.new(file.path, "application/json")
  end

  def uuid_pattern
    /\b[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}\b/i
  end
end
