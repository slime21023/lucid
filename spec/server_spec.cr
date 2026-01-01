require "./spec_helper"

# Mock Transport
class MockTransport < Mcp::Transport::Base
  property sent_messages : Array(Mcp::Protocol::Message) = [] of Mcp::Protocol::Message
  property started : Bool = false
  property closed : Bool = false

  def start
    @started = true
  end

  def send(message : Mcp::Protocol::Message)
    @sent_messages << message
  end

  def close
    @closed = true
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

class ErrorServer < Mcp::Server
  tool("boom", "Raises error") do |_args|
    raise "boom"
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

  it "starts and closes the underlying transport" do
    transport = MockTransport.new
    server = TestServer.new(transport)

    server.start
    transport.started.should be_true

    server.close
    transport.closed.should be_true
  end

  it "returns METHOD_NOT_FOUND for unknown request method" do
    transport = MockTransport.new
    server = TestServer.new(transport)

    transport.inject(Mcp::Protocol::Request.new("unknown/method", nil, 10))

    last_msg = transport.sent_messages.last.as(Mcp::Protocol::Error)
    last_msg.error.code.should eq Mcp::Protocol::Error::METHOD_NOT_FOUND
    last_msg.id.should eq 10
  end

  it "ignores notifications/initialized notifications" do
    transport = MockTransport.new
    server = TestServer.new(transport)

    transport.inject(Mcp::Protocol::Notification.new(Mcp::Protocol::Methods::NOTIFICATIONS_INITIALIZED))
    transport.sent_messages.size.should eq 0
  end

  it "returns INVALID_PARAMS when tools/call has no params" do
    transport = MockTransport.new
    server = TestServer.new(transport)

    transport.inject(Mcp::Protocol::Request.new(Mcp::Protocol::Methods::TOOLS_CALL, nil, 11))
    last_msg = transport.sent_messages.last.as(Mcp::Protocol::Error)
    last_msg.error.code.should eq Mcp::Protocol::Error::INVALID_PARAMS
  end

  it "returns METHOD_NOT_FOUND when tools/call tool does not exist" do
    transport = MockTransport.new
    server = TestServer.new(transport)

    params = JSON.parse(%({"name": "missing", "arguments": {}}))
    transport.inject(Mcp::Protocol::Request.new(Mcp::Protocol::Methods::TOOLS_CALL, params, 12))
    Fiber.yield

    last_msg = transport.sent_messages.last.as(Mcp::Protocol::Error)
    last_msg.error.code.should eq Mcp::Protocol::Error::METHOD_NOT_FOUND
  end

  it "returns INTERNAL_ERROR when tool handler raises" do
    transport = MockTransport.new
    server = ErrorServer.new(transport)

    params = JSON.parse(%({"name": "boom", "arguments": {}}))
    transport.inject(Mcp::Protocol::Request.new(Mcp::Protocol::Methods::TOOLS_CALL, params, 13))
    Fiber.yield

    last_msg = transport.sent_messages.last.as(Mcp::Protocol::Error)
    last_msg.error.code.should eq Mcp::Protocol::Error::INTERNAL_ERROR
  end
end
