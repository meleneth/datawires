# frozen_string_literal: true

require "rails_helper"

RSpec.describe Sources::Adapters::HttpJson do
  subject(:adapter) { described_class.new(configuration:, credential:) }

  let(:configuration) { { "url" => "https://public.test/data", "items_pointer" => "/items" } }
  let(:credential) { { "headers" => { "Authorization" => "Bearer secret", "Cookie" => "blocked" } } }

  before do
    allow(Sources::NetworkPolicy).to receive(:resolve!).and_return("8.8.8.8")
  end

  it "validates configuration shape, URI, and method without performing I/O" do
    expect(described_class.validate(nil)).to eq([ "config must be an object" ])
    expect(described_class.validate({ "url" => "://", "method" => "POST" })).to contain_exactly(
      "config.url must be a valid URI", "config.method must be GET"
    )
    expect(described_class.validate({ "url" => "ftp://public.test/data" })).to eq(
      [ "config.url must use HTTP or HTTPS" ]
    )
    expect(described_class.validate({ "url" => "https://public.test/data" })).to be_empty
  end

  it "filters headers, extracts arrays with JSON Pointer, and returns response metadata" do
    response = response(Net::HTTPOK, body: JSON.generate("items" => [ { "value" => 1 } ]))
    http = configured_http
    expect(http).to receive(:request) do |request|
      expect(request["Authorization"]).to eq("Bearer secret")
      expect(request["Cookie"]).to be_nil
      response
    end
    result = adapter.call

    expect(result.items).to eq([ { "value" => 1 } ])
    expect(result.metadata).to eq("http_status" => 200)
  end

  it "normalizes a selected scalar to one item" do
    http = configured_http
    allow(http).to receive(:request).and_return(response(Net::HTTPOK, body: JSON.generate("items" => 7)))

    expect(adapter.call.items).to eq([ 7 ])
  end

  it "classifies unsuccessful HTTP responses and malformed JSON" do
    http = configured_http
    allow(http).to receive(:request).and_return(response(Net::HTTPServiceUnavailable, body: "later"))
    expect { adapter.call }.to raise_error(described_class::ResponseError, "HTTP 503")

    allow(http).to receive(:request).and_return(response(Net::HTTPOK, body: "not-json"))
    expect { adapter.call }.to raise_error(described_class::ResponseError, /not valid JSON/)
  end

  def response(type, body:)
    type.new("1.1", type == Net::HTTPOK ? "200" : "503", "response").tap do |value|
      value.instance_variable_set(:@read, true)
      value.instance_variable_set(:@body, body)
    end
  end

  def configured_http
    instance_double(Net::HTTP).tap do |http|
      allow(Net::HTTP).to receive(:new).with("public.test", 443).and_return(http)
      allow(http).to receive(:ipaddr=).with("8.8.8.8")
      allow(http).to receive(:use_ssl=).with(true)
      allow(http).to receive(:open_timeout=).with(5)
      allow(http).to receive(:read_timeout=).with(15)
      allow(http).to receive(:start).and_yield(http)
    end
  end
end
