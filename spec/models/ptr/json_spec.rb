# frozen_string_literal: true

require "rails_helper"

RSpec.describe Ptr::Json do
  describe ".root" do
    it "builds a root pointer with the given body" do
      body = { "title" => "Hello" }

      ptr = described_class.root(body:)

      expect(ptr.ptr).to eq("")
      expect(ptr).to be_root
      expect(ptr.value).to eq(body)
    end
  end

  describe "#initialize" do
    it "accepts the empty string as the root pointer" do
      ptr = described_class.new(body: {}, ptr: "")

      expect(ptr.ptr).to eq("")
      expect(ptr).to be_root
    end

    it "raises for an invalid pointer" do
      expect do
        described_class.new(body: {}, ptr: "nope")
      end.to raise_error(Ptr::Json::InvalidPtrError)
    end
  end

  describe "#child" do
    it "returns a new ptr at the child location" do
      ptr = described_class.new(body: { "title" => "Hello" }, ptr: "")

      child = ptr.child("title")

      expect(child.ptr).to eq("/title")
      expect(child.value).to eq("Hello")
    end
  end

  describe "#parent" do
    it "returns nil for root" do
      ptr = described_class.new(body: {}, ptr: "")

      expect(ptr.parent).to be_nil
    end

    it "returns the parent pointer for a top-level property" do
      ptr = described_class.new(body: { "title" => "Hello" }, ptr: "/title")

      parent = ptr.parent

      expect(parent.ptr).to eq("")
      expect(parent.value).to eq({ "title" => "Hello" })
    end

    it "returns the parent pointer for an array element" do
      ptr = described_class.new(body: { "items" => [ "a", "b" ] }, ptr: "/items/1")

      parent = ptr.parent

      expect(parent.ptr).to eq("/items")
      expect(parent.value).to eq([ "a", "b" ])
    end
  end

  describe "#present?" do
    it "is true for root" do
      ptr = described_class.new(body: {}, ptr: "")

      expect(ptr).to be_present
    end

    it "is true for an existing object property" do
      ptr = described_class.new(body: { "title" => "Hello" }, ptr: "/title")

      expect(ptr).to be_present
    end

    it "is false for a missing object property" do
      ptr = described_class.new(body: { "title" => "Hello" }, ptr: "/subtitle")

      expect(ptr).not_to be_present
    end

    it "is true for an in-bounds array element" do
      ptr = described_class.new(body: { "items" => [ "a", "b" ] }, ptr: "/items/1")

      expect(ptr).to be_present
    end

    it "is false for an out-of-bounds array element" do
      ptr = described_class.new(body: { "items" => [ "a", "b" ] }, ptr: "/items/2")

      expect(ptr).not_to be_present
    end
  end

  describe "#array_element?" do
    it "is true for an array element" do
      ptr = described_class.new(body: { "items" => [ "a" ] }, ptr: "/items/0")

      expect(ptr).to be_array_element
    end

    it "is false for an object property" do
      ptr = described_class.new(body: { "title" => "Hello" }, ptr: "/title")

      expect(ptr).not_to be_array_element
    end
  end

  describe "#object_property?" do
    it "is true for an object property" do
      ptr = described_class.new(body: { "title" => "Hello" }, ptr: "/title")

      expect(ptr).to be_object_property
    end

    it "is false for an array element" do
      ptr = described_class.new(body: { "items" => [ "a" ] }, ptr: "/items/0")

      expect(ptr).not_to be_object_property
    end
  end

  describe "#children" do
    it "returns object children sorted by key" do
      ptr = described_class.new(body: { "b" => 2, "a" => 1 }, ptr: "")

      expect(ptr.children.map(&:ptr)).to eq([ "/a", "/b" ])
    end

    it "returns array element children by index" do
      ptr = described_class.new(body: { "items" => [ "a", "b" ] }, ptr: "/items")

      expect(ptr.children.map(&:ptr)).to eq([ "/items/0", "/items/1" ])
    end

    it "returns no children for scalars" do
      ptr = described_class.new(body: { "title" => "Hello" }, ptr: "/title")

      expect(ptr.children).to eq([])
    end
  end
end
