require "./spec_helper"

describe Mcp::Schema::Builder do
  it "maps common Crystal types to JSON Schema types" do
    Mcp::Schema::Builder.json_type_for("Int32").should eq "number"
    Mcp::Schema::Builder.json_type_for("Float64").should eq "number"
    Mcp::Schema::Builder.json_type_for("Bool").should eq "boolean"
    Mcp::Schema::Builder.json_type_for("String").should eq "string"
    Mcp::Schema::Builder.json_type_for("Custom").should eq "string"
  end

  it "builds an object schema with required fields" do
    schema = Mcp::Schema::Builder.object({"x" => "number", "y" => "string"}, ["x"])
    schema["type"].as_s.should eq "object"
    schema["required"].as_a.map(&.as_s).should eq ["x"]
    schema["properties"]["y"]["type"].as_s.should eq "string"
  end
end

