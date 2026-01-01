require "./spec_helper"

describe Mcp::Types do
  describe Mcp::Types::ToolsListResult do
    it "round-trips tools list payload" do
      schema = JSON.parse(%({"type":"object","properties":{"x":{"type":"number"}},"required":["x"]}))
      payload = Mcp::Types::ToolsListResult.new(
        tools: [
          Mcp::Types::Tool.new(name: "add", description: "Add", input_schema: schema),
        ]
      )

      parsed = JSON.parse(payload.to_json)
      parsed["tools"].as_a.size.should eq 1
      parsed["tools"][0]["inputSchema"]["properties"]["x"]["type"].as_s.should eq "number"

      decoded = Mcp::Types::ToolsListResult.from_json(payload.to_json)
      decoded.tools[0].name.should eq "add"
    end
  end

  describe Mcp::Types::ToolCallResult do
    it "serializes text content" do
      payload = Mcp::Types::ToolCallResult.new(
        content: [Mcp::Types::TextContent.new("Hello")]
      )

      parsed = JSON.parse(payload.to_json)
      parsed["content"][0]["type"].as_s.should eq "text"
      parsed["content"][0]["text"].as_s.should eq "Hello"
    end
  end
end

