require "./spec_helper"

# Mock Transport
class MockTransport < Mcp::Transport::Base
  property sent_messages : Array(Mcp::Protocol::Message) = [] of Mcp::Protocol::Message

  def start
  end

  def send(message : Mcp::Protocol::Message)
    @sent_messages << message
  end

  def close
  end

  def inject(message : Mcp::Protocol::Message)
    @on_message.try &.call(message)
  end
end

# Define a Test Server Class
class TestServer < Mcp::Server
  tool("add", "Add numbers", x: Int32, y: Int32) do |args|
    args.x + args.y
  end

  tool("echo", "Echo", msg: String) do |args|
    args.msg
  end
end

describe Mcp::Server do
  it "registers tools and generates schema" do
    transport = MockTransport.new
    server = TestServer.new(transport)

    # List tools
    transport.inject(Mcp::Protocol::Request.new(Mcp::Protocol::Methods::TOOLS_LIST, nil, 1))

    last_msg = transport.sent_messages.last.as(Mcp::Protocol::Result)
    tools = last_msg.result["tools"].as_a
    # Should have 2 tools
    tools.size.should eq 2

    add_tool = tools.find { |t| t["name"] == "add" }.not_nil!
    add_tool["inputSchema"]["properties"]["x"]["type"].should eq "number"
  end

  it "executes tools via tools/call" do
    transport = MockTransport.new
    server = TestServer.new(transport)

    # Call tool
    params = JSON.parse(%({"name": "echo", "arguments": {"msg": "Hello"}}))
    transport.inject(Mcp::Protocol::Request.new(Mcp::Protocol::Methods::TOOLS_CALL, params, 2))

    Fiber.yield

    last_msg = transport.sent_messages.last.as(Mcp::Protocol::Result)
    content = last_msg.result["content"].as_a
    content[0]["text"].as_s.should eq "Hello"
  end
end
