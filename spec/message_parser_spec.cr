require "./spec_helper"

describe Mcp::Protocol::MessageParser do
  it "parses Request" do
    msg = Mcp::Protocol::MessageParser.parse(%({"jsonrpc":"2.0","method":"x","params":{"a":1},"id":1}))
    msg.should be_a(Mcp::Protocol::Request)
    msg.as(Mcp::Protocol::Request).method.should eq "x"
  end

  it "parses Notification" do
    msg = Mcp::Protocol::MessageParser.parse(%({"jsonrpc":"2.0","method":"x","params":{"a":1}}))
    msg.should be_a(Mcp::Protocol::Notification)
    msg.as(Mcp::Protocol::Notification).method.should eq "x"
  end

  it "parses Result" do
    msg = Mcp::Protocol::MessageParser.parse(%({"jsonrpc":"2.0","result":{"ok":true},"id":"1"}))
    msg.should be_a(Mcp::Protocol::Result)
    msg.as(Mcp::Protocol::Result).id.should eq "1"
  end

  it "parses Error" do
    msg = Mcp::Protocol::MessageParser.parse(%({"jsonrpc":"2.0","error":{"code":-32601,"message":"nope"},"id":1}))
    msg.should be_a(Mcp::Protocol::Error)
    msg.as(Mcp::Protocol::Error).error.code.should eq -32601
  end

  it "returns nil for unknown message shape" do
    Mcp::Protocol::MessageParser.parse(%({"jsonrpc":"2.0"})).should be_nil
  end

  it "returns nil for malformed JSON" do
    Mcp::Protocol::MessageParser.parse(%({)).should be_nil
  end
end

