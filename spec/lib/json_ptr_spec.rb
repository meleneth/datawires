# frozen_string_literal: true

require "rails_helper"
require "json_ptr"

RSpec.describe JsonPtr do
  describe "tokens" do
    it "escapes and unescapes ~ and / correctly" do
      u = JsonPtr::UnescapedToken.new("a~b/c")
      expect(u.escaped).to eq("a~0b~1c")

      e = JsonPtr::EscapedToken.new("a~0b~1c")
      expect(e.unescaped).to eq("a~b/c")
    end

    it "compares tokens by unescaped value" do
      u = JsonPtr::UnescapedToken.new("a/b")
      e = JsonPtr::EscapedToken.new("a~1b")
      expect(u).to eq(e)
      expect(u.hash).to eq(e.hash)
    end
  end

  describe JsonPtr::Pointer do
    it "treats empty and / as root" do
      expect(described_class.parse("").to_s).to eq("")
      expect(described_class.parse("/").to_s).to eq("")
    end

    it "parses and roundtrips a normal pointer" do
      p = described_class.parse("/properties/foo/title")
      expect(p.to_s).to eq("/properties/foo/title")
      expect(p.tokens.map(&:unescaped)).to eq(%w[properties foo title])
    end

    it "parses escaped segments into unescaped tokens" do
      p = described_class.parse("/properties/foo~1bar/~0tilde")
      expect(p.tokens.map(&:unescaped)).to eq(["properties", "foo/bar", "~tilde"])
      expect(p.to_s).to eq("/properties/foo~1bar/~0tilde")
    end

    it "rejects non-root pointers that don't start with /" do
      expect { described_class.parse("properties/foo") }.to raise_error(ArgumentError)
    end

    it "supports child and parent" do
      p = described_class.parse("/a/b")
      c = p.child("c")
      expect(c.to_s).to eq("/a/b/c")
      expect(c.parent.to_s).to eq("/a/b")
      expect(c.parent.parent.to_s).to eq("/a")
      expect(c.parent.parent.parent.to_s).to eq("")
    end
  end

  describe ".get" do
    it "reads hash values using symbol-first, string fallback" do
      doc = { a: { "b" => 123 } }

      expect(described_class.get(doc, "/a/b")).to eq(123)
    end

    it "reads string keys when symbol key missing" do
      doc = { "a" => { "b" => 123 } }
      expect(described_class.get(doc, "/a/b")).to eq(123)
    end

    it "reads symbol keys when string key missing" do
      doc = { a: { b: 123 } }
      expect(described_class.get(doc, "/a/b")).to eq(123)
    end

    it "returns nil if the path is missing" do
      doc = { a: { b: 123 } }
      expect(described_class.get(doc, "/a/nope")).to be_nil
    end

    it "indexes arrays using integer tokens" do
      doc = { a: [10, 20, 30] }
      expect(described_class.get(doc, "/a/1")).to eq(20)
    end

    it "returns nil for non-integer array token" do
      doc = { a: [10, 20, 30] }
      expect(described_class.get(doc, "/a/nope")).to be_nil
    end

    it "accepts a Pointer instance" do
      doc = { a: { b: 123 } }
      ptr = JsonPtr::Pointer.parse("/a/b")
      expect(described_class.get(doc, ptr)).to eq(123)
    end
  end

  describe ".set" do
    it "immutably sets a value at a hash path" do
      doc = { a: { b: 1 } }
      updated = described_class.set(doc, "/a/b", 999)

      expect(updated).to eq(a: { b: 999 })
      expect(doc).to eq(a: { b: 1 }) # original untouched
    end

    it "immutably sets a value in an array" do
      doc = { a: [10, 20, 30] }
      updated = described_class.set(doc, "/a/1", 999)

      expect(updated).to eq(a: [10, 999, 30])
      expect(doc).to eq(a: [10, 20, 30])
    end

    it "raises if parent path is missing (no autovivify in v1)" do
      doc = {}
      expect { described_class.set(doc, "/a/b", 1) }.to raise_error(KeyError)
    end

    it "replaces the whole document when setting root" do
      doc = { a: 1 }
      updated = described_class.set(doc, "", { z: 9 })
      expect(updated).to eq(z: 9)
    end
  end

  describe ".each_pointer" do
    it "yields the root pointer first" do
      doc = { a: 1 }
      pairs = described_class.each_pointer(doc).take(2)
      expect(pairs.first.first.to_s).to eq("")
      expect(pairs.first.last).to eq(doc)
    end

    it "enumerates hash keys in schema-friendly priority order, then lexicographically" do
      # Force a custom priority list so the test is explicit and stable
      key_order = JsonPtr::KeyOrder.new(priority: %w[title type properties])

      doc = {
        "z" => 1,
        "type" => "object",
        "title" => "Hello",
        "properties" => { "b" => 2, "a" => 1 },
        "a" => 0
      }

      # Collect only first-level child pointers
      first_level = []
      described_class.each_pointer(doc, key_order: key_order) do |ptr, value|
        next unless ptr.tokens.length == 1
        first_level << ptr.to_s
      end

      expect(first_level).to eq([
        "/title",
        "/type",
        "/properties",
        "/a",
        "/z"
      ])
    end

    it "enumerates arrays by index order" do
      doc = { a: [10, 20] }
      ptrs = []
      described_class.each_pointer(doc) do |ptr, _|
        ptrs << ptr.to_s
      end

      expect(ptrs).to include("/a/0", "/a/1")
      # and ensure /a/0 comes before /a/1
      expect(ptrs.index("/a/0")).to be < ptrs.index("/a/1")
    end
  end
end
