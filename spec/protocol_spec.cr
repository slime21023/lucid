require "./spec_helper"

describe Mcp::Protocol do
  describe Mcp::Protocol::Request do
    it "serializes to JSON" do
      req = Mcp::Protocol::Request.new("add", JSON.parse("[1, 2]"), 1)
      json = req.to_json
      parsed = JSON.parse(json)
      parsed["jsonrpc"].should eq "2.0"
      parsed["method"].should eq "add"
      parsed["id"].should eq 1
    end

    it "deserializes from JSON" do
      json = %({"jsonrpc": "2.0", "method": "sub", "params": {"x": 10}, "id": "req-1"})
      req = Mcp::Protocol::Request.from_json(json)
      req.method.should eq "sub"
      req.id.should eq "req-1"
      req.params.not_nil!["x"].as_i.should eq 10
    end
  end

  describe Mcp::Protocol::Result do
    it "handles result data" do
      res = Mcp::Protocol::Result.new(JSON.parse(%({"sum": 3})), 1)
      res.result["sum"].as_i.should eq 3
    end
  end
end
