require "./spec_helper"

describe Mcp::Types do
  describe Mcp::Types::InitializeResult do
    it "serializes with MCP field names" do
      result = Mcp::Types::InitializeResult.new(
        protocol_version: "2024-11-05",
        capabilities: Mcp::Types::Capabilities.new(
          tools: Mcp::Types::ToolsCapabilities.new(list_changed: true),
          roots: nil
        ),
        server_info: Mcp::Types::ServerInfo.new(name: "Test", version: "0.0.0")
      )

      parsed = JSON.parse(result.to_json)
      parsed["protocolVersion"].as_s.should eq "2024-11-05"
      parsed["serverInfo"]["name"].as_s.should eq "Test"
      parsed["capabilities"]["tools"]["listChanged"].as_bool.should eq true
    end

    it "deserializes from JSON" do
      json = %({
        "protocolVersion": "2024-11-05",
        "capabilities": {"tools": {"listChanged": true}},
        "serverInfo": {"name": "X", "version": "1.2.3"}
      })

      result = Mcp::Types::InitializeResult.from_json(json)
      result.protocol_version.should eq "2024-11-05"
      result.server_info.version.should eq "1.2.3"
      result.capabilities.tools.not_nil!.list_changed.should eq true
    end
  end
end

