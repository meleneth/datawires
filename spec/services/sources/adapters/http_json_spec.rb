# frozen_string_literal: true

require "rails_helper"

RSpec.describe Sources::Adapters::HttpJson do
  subject(:adapter) { described_class.new(configuration:, credential:) }

  let(:configuration) { { "url" => "https://public.test/data", "items_pointer" => "/items" } }
  let(:credential) { { "headers" => { "Authorization" => "Bearer secret", "Cookie" => "blocked" } } }

  before do
    allow(Sources::NetworkPolicy).to receive(:validate!).and_return(true)
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
    http = instance_double(Net::HTTP)
    expect(http).to receive(:request) do |request|
      expect(request["Authorization"]).to eq("Bearer secret")
      expect(request["Cookie"]).to be_nil
      response
    end
    allow(Net::HTTP).to receive(:start).and_yield(http)

    result = adapter.call

    expect(result.items).to eq([ { "value" => 1 } ])
    expect(result.metadata).to eq("http_status" => 200)
  end

  it "normalizes a selected scalar to one item" do
    allow(Net::HTTP).to receive(:start).and_yield(
      instance_double(Net::HTTP, request: response(Net::HTTPOK, body: JSON.generate("items" => 7)))
    )

    expect(adapter.call.items).to eq([ 7 ])
  end

  it "classifies unsuccessful HTTP responses and malformed JSON" do
    http = instance_double(Net::HTTP)
    allow(Net::HTTP).to receive(:start).and_yield(http)
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
end
