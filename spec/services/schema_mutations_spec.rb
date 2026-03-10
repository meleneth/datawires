# spec/services/schema_mutations_spec.rb
# frozen_string_literal: true

require "rails_helper"

RSpec.describe SchemaMutations do
  describe ".ensure_object_root!" do
    it "initializes the root object schema shape" do
      body = {}

      described_class.ensure_object_root!(body)

      expect(body).to eq(
        "type" => "object",
        "properties" => {},
        "required" => [],
      )
    end

    it "does not clobber existing root values" do
      body = {
        "type" => "object",
        "properties" => { "name" => { "type" => "string" } },
        "required" => ["name"],
      }

      described_class.ensure_object_root!(body)

      expect(body).to eq(
        "type" => "object",
        "properties" => { "name" => { "type" => "string" } },
        "required" => ["name"],
      )
    end

    it "initializes a nested object schema at the given pointer" do
      body = {
        "type" => "object",
        "properties" => {
          "address" => {}
        }
      }

      described_class.ensure_object_root!(body, at: "/properties/address")

      expect(body).to eq(
        "type" => "object",
        "properties" => {
          "address" => {
            "type" => "object",
            "properties" => {},
            "required" => [],
          }
        }
      )
    end
  end

  describe ".add_property!" do
    it "adds a property at the root" do
      body = {
        "type" => "object",
        "properties" => {},
        "required" => [],
      }

      described_class.add_property!(body, name: "name", type: "string", required: false)

      expect(body["properties"]).to eq(
        "name" => { "type" => "string" }
      )
      expect(body["required"]).to eq([])
    end

    it "adds a required property at the root" do
      body = {
        "type" => "object",
        "properties" => {},
        "required" => [],
      }

      described_class.add_property!(body, name: "name", type: "string", required: true)

      expect(body["properties"]).to eq(
        "name" => { "type" => "string" }
      )
      expect(body["required"]).to eq(["name"])
    end

    it "adds an object property with object defaults" do
      body = {
        "type" => "object",
        "properties" => {},
        "required" => [],
      }

      described_class.add_property!(body, name: "address", type: "object", required: false)

      expect(body["properties"]["address"]).to eq(
        "type" => "object",
        "properties" => {},
        "required" => [],
      )
    end

    it "adds an array property with items" do
      body = {
        "type" => "object",
        "properties" => {},
        "required" => [],
      }

      described_class.add_property!(body, name: "tags", type: "array", required: false)

      expect(body["properties"]["tags"]).to eq(
        "type" => "array",
        "items" => {},
      )
    end

    it "adds a nested property at the given pointer" do
      body = {
        "type" => "object",
        "properties" => {
          "address" => {
            "type" => "object",
            "properties" => {},
            "required" => [],
          }
        },
        "required" => [],
      }

      described_class.add_property!(
        body,
        at: "/properties/address",
        name: "city",
        type: "string",
        required: true,
      )

      expect(body["properties"]["address"]["properties"]).to eq(
        "city" => { "type" => "string" }
      )
      expect(body["properties"]["address"]["required"]).to eq(["city"])
    end

    it "raises if the property already exists" do
      body = {
        "type" => "object",
        "properties" => {
          "name" => { "type" => "string" }
        },
        "required" => [],
      }

      expect do
        described_class.add_property!(body, name: "name", type: "string", required: false)
      end.to raise_error(ArgumentError, "property exists")
    end

    it "raises if the target path does not exist" do
      body = {
        "type" => "object",
        "properties" => {},
        "required" => [],
      }

      expect do
        described_class.add_property!(
          body,
          at: "/properties/address",
          name: "city",
          type: "string",
          required: false,
        )
      end.to raise_error(KeyError, /missing path/i)
    end

    it "raises if the target node is not an object schema" do
      body = {
        "type" => "object",
        "properties" => {
          "name" => { "type" => "string" }
        },
        "required" => [],
      }

      expect do
        described_class.add_property!(
          body,
          at: "/properties/name",
          name: "first",
          type: "string",
          required: false,
        )
      end.to raise_error(ArgumentError, /not an object schema/i)
    end
  end

  describe ".remove_property!" do
    it "removes the property and its required entry" do
      body = {
        "type" => "object",
        "properties" => {
          "name" => { "type" => "string" },
          "age" => { "type" => "integer" },
        },
        "required" => ["name"],
      }

      described_class.remove_property!(body, name: "name")

      expect(body["properties"]).to eq(
        "age" => { "type" => "integer" }
      )
      expect(body["required"]).to eq([])
    end

    it "removes a nested property" do
      body = {
        "type" => "object",
        "properties" => {
          "address" => {
            "type" => "object",
            "properties" => {
              "city" => { "type" => "string" },
              "zip" => { "type" => "string" },
            },
            "required" => ["city"],
          }
        },
        "required" => [],
      }

      described_class.remove_property!(body, at: "/properties/address", name: "city")

      expect(body["properties"]["address"]["properties"]).to eq(
        "zip" => { "type" => "string" }
      )
      expect(body["properties"]["address"]["required"]).to eq([])
    end
  end

  describe ".rename_property!" do
    it "renames the property and updates required" do
      body = {
        "type" => "object",
        "properties" => {
          "name" => { "type" => "string" }
        },
        "required" => ["name"],
      }

      described_class.rename_property!(body, old_name: "name", new_name: "full_name")

      expect(body["properties"]).to eq(
        "full_name" => { "type" => "string" }
      )
      expect(body["required"]).to eq(["full_name"])
    end

    it "renames a nested property" do
      body = {
        "type" => "object",
        "properties" => {
          "address" => {
            "type" => "object",
            "properties" => {
              "city" => { "type" => "string" }
            },
            "required" => ["city"],
          }
        },
        "required" => [],
      }

      described_class.rename_property!(
        body,
        at: "/properties/address",
        old_name: "city",
        new_name: "municipality",
      )

      expect(body["properties"]["address"]["properties"]).to eq(
        "municipality" => { "type" => "string" }
      )
      expect(body["properties"]["address"]["required"]).to eq(["municipality"])
    end

    it "raises if the old property is missing" do
      body = {
        "type" => "object",
        "properties" => {},
        "required" => [],
      }

      expect do
        described_class.rename_property!(body, old_name: "name", new_name: "full_name")
      end.to raise_error(ArgumentError, "missing property")
    end

    it "raises if the new property already exists" do
      body = {
        "type" => "object",
        "properties" => {
          "name" => { "type" => "string" },
          "full_name" => { "type" => "string" },
        },
        "required" => [],
      }

      expect do
        described_class.rename_property!(body, old_name: "name", new_name: "full_name")
      end.to raise_error(ArgumentError, "property exists")
    end
  end

  describe ".change_property_type!" do
    it "changes a primitive property type" do
      body = {
        "type" => "object",
        "properties" => {
          "name" => { "type" => "string" }
        },
        "required" => [],
      }

      described_class.change_property_type!(body, name: "name", type: "integer")

      expect(body["properties"]["name"]).to eq(
        "type" => "integer"
      )
    end

    it "changes a property to object and initializes object fields" do
      body = {
        "type" => "object",
        "properties" => {
          "metadata" => { "type" => "string" }
        },
        "required" => [],
      }

      described_class.change_property_type!(body, name: "metadata", type: "object")

      expect(body["properties"]["metadata"]).to eq(
        "type" => "object",
        "properties" => {},
        "required" => [],
      )
    end

    it "changes a property to array and initializes items" do
      body = {
        "type" => "object",
        "properties" => {
          "tags" => { "type" => "string" }
        },
        "required" => [],
      }

      described_class.change_property_type!(body, name: "tags", type: "array")

      expect(body["properties"]["tags"]).to eq(
        "type" => "array",
        "items" => {},
      )
    end

    it "removes object-specific keys when changing to a primitive type" do
      body = {
        "type" => "object",
        "properties" => {
          "address" => {
            "type" => "object",
            "properties" => { "city" => { "type" => "string" } },
            "required" => ["city"],
          }
        },
        "required" => [],
      }

      described_class.change_property_type!(body, name: "address", type: "string")

      expect(body["properties"]["address"]).to eq(
        "type" => "string"
      )
    end

    it "raises if the property is missing" do
      body = {
        "type" => "object",
        "properties" => {},
        "required" => [],
      }

      expect do
        described_class.change_property_type!(body, name: "name", type: "string")
      end.to raise_error(ArgumentError, "missing property")
    end
  end

  describe ".set_required!" do
    it "adds a property to required" do
      body = {
        "type" => "object",
        "properties" => {
          "name" => { "type" => "string" }
        },
        "required" => [],
      }

      described_class.set_required!(body, name: "name", required: true)

      expect(body["required"]).to eq(["name"])
    end

    it "does not duplicate required entries" do
      body = {
        "type" => "object",
        "properties" => {
          "name" => { "type" => "string" }
        },
        "required" => ["name"],
      }

      described_class.set_required!(body, name: "name", required: true)

      expect(body["required"]).to eq(["name"])
    end

    it "removes a property from required" do
      body = {
        "type" => "object",
        "properties" => {
          "name" => { "type" => "string" }
        },
        "required" => ["name"],
      }

      described_class.set_required!(body, name: "name", required: false)

      expect(body["required"]).to eq([])
    end

    it "sets required on a nested object schema" do
      body = {
        "type" => "object",
        "properties" => {
          "address" => {
            "type" => "object",
            "properties" => {
              "city" => { "type" => "string" }
            },
            "required" => [],
          }
        },
        "required" => [],
      }

      described_class.set_required!(body, at: "/properties/address", name: "city", required: true)

      expect(body["properties"]["address"]["required"]).to eq(["city"])
    end
  end
end# spec/services/schema_mutations_spec.rb
# frozen_string_literal: true

require "rails_helper"

RSpec.describe SchemaMutations do
  describe ".ensure_object_root!" do
    it "initializes the root object schema shape" do
      body = {}

      described_class.ensure_object_root!(body)

      expect(body).to eq(
        "type" => "object",
        "properties" => {},
        "required" => [],
      )
    end

    it "does not clobber existing root values" do
      body = {
        "type" => "object",
        "properties" => { "name" => { "type" => "string" } },
        "required" => ["name"],
      }

      described_class.ensure_object_root!(body)

      expect(body).to eq(
        "type" => "object",
        "properties" => { "name" => { "type" => "string" } },
        "required" => ["name"],
      )
    end

    it "initializes a nested object schema at the given pointer" do
      body = {
        "type" => "object",
        "properties" => {
          "address" => {}
        }
      }

      described_class.ensure_object_root!(body, at: "/properties/address")

      expect(body).to eq(
        "type" => "object",
        "properties" => {
          "address" => {
            "type" => "object",
            "properties" => {},
            "required" => [],
          }
        }
      )
    end
  end

  describe ".add_property!" do
    it "adds a property at the root" do
      body = {
        "type" => "object",
        "properties" => {},
        "required" => [],
      }

      described_class.add_property!(body, name: "name", type: "string", required: false)

      expect(body["properties"]).to eq(
        "name" => { "type" => "string" }
      )
      expect(body["required"]).to eq([])
    end

    it "adds a required property at the root" do
      body = {
        "type" => "object",
        "properties" => {},
        "required" => [],
      }

      described_class.add_property!(body, name: "name", type: "string", required: true)

      expect(body["properties"]).to eq(
        "name" => { "type" => "string" }
      )
      expect(body["required"]).to eq(["name"])
    end

    it "adds an object property with object defaults" do
      body = {
        "type" => "object",
        "properties" => {},
        "required" => [],
      }

      described_class.add_property!(body, name: "address", type: "object", required: false)

      expect(body["properties"]["address"]).to eq(
        "type" => "object",
        "properties" => {},
        "required" => [],
      )
    end

    it "adds an array property with items" do
      body = {
        "type" => "object",
        "properties" => {},
        "required" => [],
      }

      described_class.add_property!(body, name: "tags", type: "array", required: false)

      expect(body["properties"]["tags"]).to eq(
        "type" => "array",
        "items" => {},
      )
    end

    it "adds a nested property at the given pointer" do
      body = {
        "type" => "object",
        "properties" => {
          "address" => {
            "type" => "object",
            "properties" => {},
            "required" => [],
          }
        },
        "required" => [],
      }

      described_class.add_property!(
        body,
        at: "/properties/address",
        name: "city",
        type: "string",
        required: true,
      )

      expect(body["properties"]["address"]["properties"]).to eq(
        "city" => { "type" => "string" }
      )
      expect(body["properties"]["address"]["required"]).to eq(["city"])
    end

    it "raises if the property already exists" do
      body = {
        "type" => "object",
        "properties" => {
          "name" => { "type" => "string" }
        },
        "required" => [],
      }

      expect do
        described_class.add_property!(body, name: "name", type: "string", required: false)
      end.to raise_error(ArgumentError, "property exists")
    end

    it "raises if the target path does not exist" do
      body = {
        "type" => "object",
        "properties" => {},
        "required" => [],
      }

      expect do
        described_class.add_property!(
          body,
          at: "/properties/address",
          name: "city",
          type: "string",
          required: false,
        )
      end.to raise_error(KeyError, /missing path/i)
    end

    it "raises if the target node is not an object schema" do
      body = {
        "type" => "object",
        "properties" => {
          "name" => { "type" => "string" }
        },
        "required" => [],
      }

      expect do
        described_class.add_property!(
          body,
          at: "/properties/name",
          name: "first",
          type: "string",
          required: false,
        )
      end.to raise_error(ArgumentError, /not an object schema/i)
    end
  end

  describe ".remove_property!" do
    it "removes the property and its required entry" do
      body = {
        "type" => "object",
        "properties" => {
          "name" => { "type" => "string" },
          "age" => { "type" => "integer" },
        },
        "required" => ["name"],
      }

      described_class.remove_property!(body, name: "name")

      expect(body["properties"]).to eq(
        "age" => { "type" => "integer" }
      )
      expect(body["required"]).to eq([])
    end

    it "removes a nested property" do
      body = {
        "type" => "object",
        "properties" => {
          "address" => {
            "type" => "object",
            "properties" => {
              "city" => { "type" => "string" },
              "zip" => { "type" => "string" },
            },
            "required" => ["city"],
          }
        },
        "required" => [],
      }

      described_class.remove_property!(body, at: "/properties/address", name: "city")

      expect(body["properties"]["address"]["properties"]).to eq(
        "zip" => { "type" => "string" }
      )
      expect(body["properties"]["address"]["required"]).to eq([])
    end
  end

  describe ".rename_property!" do
    it "renames the property and updates required" do
      body = {
        "type" => "object",
        "properties" => {
          "name" => { "type" => "string" }
        },
        "required" => ["name"],
      }

      described_class.rename_property!(body, old_name: "name", new_name: "full_name")

      expect(body["properties"]).to eq(
        "full_name" => { "type" => "string" }
      )
      expect(body["required"]).to eq(["full_name"])
    end

    it "renames a nested property" do
      body = {
        "type" => "object",
        "properties" => {
          "address" => {
            "type" => "object",
            "properties" => {
              "city" => { "type" => "string" }
            },
            "required" => ["city"],
          }
        },
        "required" => [],
      }

      described_class.rename_property!(
        body,
        at: "/properties/address",
        old_name: "city",
        new_name: "municipality",
      )

      expect(body["properties"]["address"]["properties"]).to eq(
        "municipality" => { "type" => "string" }
      )
      expect(body["properties"]["address"]["required"]).to eq(["municipality"])
    end

    it "raises if the old property is missing" do
      body = {
        "type" => "object",
        "properties" => {},
        "required" => [],
      }

      expect do
        described_class.rename_property!(body, old_name: "name", new_name: "full_name")
      end.to raise_error(ArgumentError, "missing property")
    end

    it "raises if the new property already exists" do
      body = {
        "type" => "object",
        "properties" => {
          "name" => { "type" => "string" },
          "full_name" => { "type" => "string" },
        },
        "required" => [],
      }

      expect do
        described_class.rename_property!(body, old_name: "name", new_name: "full_name")
      end.to raise_error(ArgumentError, "property exists")
    end
  end

  describe ".change_property_type!" do
    it "changes a primitive property type" do
      body = {
        "type" => "object",
        "properties" => {
          "name" => { "type" => "string" }
        },
        "required" => [],
      }

      described_class.change_property_type!(body, name: "name", type: "integer")

      expect(body["properties"]["name"]).to eq(
        "type" => "integer"
      )
    end

    it "changes a property to object and initializes object fields" do
      body = {
        "type" => "object",
        "properties" => {
          "metadata" => { "type" => "string" }
        },
        "required" => [],
      }

      described_class.change_property_type!(body, name: "metadata", type: "object")

      expect(body["properties"]["metadata"]).to eq(
        "type" => "object",
        "properties" => {},
        "required" => [],
      )
    end

    it "changes a property to array and initializes items" do
      body = {
        "type" => "object",
        "properties" => {
          "tags" => { "type" => "string" }
        },
        "required" => [],
      }

      described_class.change_property_type!(body, name: "tags", type: "array")

      expect(body["properties"]["tags"]).to eq(
        "type" => "array",
        "items" => {},
      )
    end

    it "removes object-specific keys when changing to a primitive type" do
      body = {
        "type" => "object",
        "properties" => {
          "address" => {
            "type" => "object",
            "properties" => { "city" => { "type" => "string" } },
            "required" => ["city"],
          }
        },
        "required" => [],
      }

      described_class.change_property_type!(body, name: "address", type: "string")

      expect(body["properties"]["address"]).to eq(
        "type" => "string"
      )
    end

    it "raises if the property is missing" do
      body = {
        "type" => "object",
        "properties" => {},
        "required" => [],
      }

      expect do
        described_class.change_property_type!(body, name: "name", type: "string")
      end.to raise_error(ArgumentError, "missing property")
    end
  end

  describe ".set_required!" do
    it "adds a property to required" do
      body = {
        "type" => "object",
        "properties" => {
          "name" => { "type" => "string" }
        },
        "required" => [],
      }

      described_class.set_required!(body, name: "name", required: true)

      expect(body["required"]).to eq(["name"])
    end

    it "does not duplicate required entries" do
      body = {
        "type" => "object",
        "properties" => {
          "name" => { "type" => "string" }
        },
        "required" => ["name"],
      }

      described_class.set_required!(body, name: "name", required: true)

      expect(body["required"]).to eq(["name"])
    end

    it "removes a property from required" do
      body = {
        "type" => "object",
        "properties" => {
          "name" => { "type" => "string" }
        },
        "required" => ["name"],
      }

      described_class.set_required!(body, name: "name", required: false)

      expect(body["required"]).to eq([])
    end

    it "sets required on a nested object schema" do
      body = {
        "type" => "object",
        "properties" => {
          "address" => {
            "type" => "object",
            "properties" => {
              "city" => { "type" => "string" }
            },
            "required" => [],
          }
        },
        "required" => [],
      }

      described_class.set_required!(body, at: "/properties/address", name: "city", required: true)

      expect(body["properties"]["address"]["required"]).to eq(["city"])
    end
  end
end
