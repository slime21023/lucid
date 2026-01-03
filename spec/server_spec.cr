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

class ServerHostMockTransport < Mcp::Transport::Base
  getter sent_messages : Array(Mcp::Protocol::Message) = [] of Mcp::Protocol::Message

  def initialize(&@responder : Mcp::Protocol::Request -> Mcp::Protocol::Message)
  end

  def initialize
    initialize do |request|
      case request.method
      when Mcp::Protocol::Methods::ROOTS_LIST
        Mcp::Protocol::Result.new(
          JSON.parse(%({"roots":[{"uri":"file:///repo","name":"repo"}]})),
          request.id.not_nil!
        )
      else
        Mcp::Protocol::Error.new(
          Mcp::Protocol::Error::ErrorData.new(Mcp::Protocol::Error::METHOD_NOT_FOUND, "no"),
          request.id
        )
      end
    end
  end

  def start
  end

  def close
  end

  def send(message : Mcp::Protocol::Message)
    @sent_messages << message

    case message
    when Mcp::Protocol::Request
      spawn do
        @on_message.try &.call(@responder.call(message))
      end
    end
  end
end

class CapabilityServer < Mcp::Server
  def initialize(transport : MockTransport)
    super(transport)

    resources.register("file://a.txt", name: "a", mime_type: "text/plain") do
      "A"
    end

    prompts.register(
      "p",
      description: "P",
      arguments: [Mcp::Types::PromptArgument.new(name: "topic", required: true)]
    ) do |_args|
      Mcp::Types::PromptsGetResult.new(
        description: "P",
        messages: [Mcp::Types::PromptMessage.new(role: "user", content: "hi")]
      )
    end
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

  it "supports resources/list and resources/read" do
    transport = MockTransport.new
    server = CapabilityServer.new(transport)

    transport.inject(Mcp::Protocol::Request.new(Mcp::Protocol::Methods::RESOURCES_LIST, nil, 20))
    list_msg = transport.sent_messages.last.as(Mcp::Protocol::Result)
    list_msg.result["resources"].as_a[0]["uri"].as_s.should eq "file://a.txt"

    params = JSON.parse(%({"uri":"file://a.txt"}))
    transport.inject(Mcp::Protocol::Request.new(Mcp::Protocol::Methods::RESOURCES_READ, params, 21))
    read_msg = transport.sent_messages.last.as(Mcp::Protocol::Result)
    read_msg.result["contents"].as_a[0]["text"].as_s.should eq "A"
  end

  it "supports prompts/list and prompts/get" do
    transport = MockTransport.new
    server = CapabilityServer.new(transport)

    transport.inject(Mcp::Protocol::Request.new(Mcp::Protocol::Methods::PROMPTS_LIST, nil, 30))
    list_msg = transport.sent_messages.last.as(Mcp::Protocol::Result)
    list_msg.result["prompts"].as_a[0]["name"].as_s.should eq "p"

    params = JSON.parse(%({"name":"p","arguments":{"topic":"x"}}))
    transport.inject(Mcp::Protocol::Request.new(Mcp::Protocol::Methods::PROMPTS_GET, params, 31))
    get_msg = transport.sent_messages.last.as(Mcp::Protocol::Result)
    get_msg.result["messages"].as_a[0]["content"].as_s.should eq "hi"
  end

  it "supports logging/setLevel" do
    transport = MockTransport.new
    server = CapabilityServer.new(transport)

    params = JSON.parse(%({"level":"debug"}))
    transport.inject(Mcp::Protocol::Request.new(Mcp::Protocol::Methods::LOGGING_SET_LEVEL, params, 40))
    server.log_level.should eq "debug"

    msg = transport.sent_messages.last.as(Mcp::Protocol::Result)
    msg.result.as_h.size.should eq 0
  end

  it "supports server -> host roots/list requests (typed + error path)" do
    transport = ServerHostMockTransport.new
    server = Mcp::Server.new(transport)

    res = server.list_roots_typed
    res.should be_a(Mcp::Types::RootsListResult)
    res.as(Mcp::Types::RootsListResult).roots[0].uri.should eq "file:///repo"

    # Force decode failure to exercise the typed error path.
    bad_transport = ServerHostMockTransport.new do |request|
      Mcp::Protocol::Result.new(JSON.parse(%({"not":"roots"})), request.id.not_nil!)
    end
    server2 = Mcp::Server.new(bad_transport)
    bad = server2.list_roots_typed
    bad.should be_a(Mcp::Protocol::Error)
    bad.as(Mcp::Protocol::Error).error.code.should eq Mcp::Protocol::Error::INTERNAL_ERROR
  end

  it "sends logging/message notifications via log helpers" do
    transport = MockTransport.new
    server = Mcp::Server.new(transport)

    server.log_info("hi", "test")
    server.log_debug("d", "test")
    server.log_warn("w", "test")
    server.log_error("e", "test")
    msg = transport.sent_messages.last.as(Mcp::Protocol::Notification)
    msg.method.should eq Mcp::Protocol::Methods::LOGGING_MESSAGE
    msg.params.not_nil!["message"].as_s.should eq "e"

    server.send_notification("ping", JSON.parse(%({"x":1})))
    msg2 = transport.sent_messages.last.as(Mcp::Protocol::Notification)
    msg2.method.should eq "ping"
    msg2.params.not_nil!["x"].as_i.should eq 1
  end

  it "initializes a ToolRegistry empty" do
    registry = Mcp::ServerDSL::ToolRegistry.new
    registry.values.size.should eq 0
  end
end
