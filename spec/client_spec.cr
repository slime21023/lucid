require "./spec_helper"

class ClientMockTransport < Mcp::Transport::Base
  getter started = false
  getter sent_messages : Array(Mcp::Protocol::Message) = [] of Mcp::Protocol::Message

  def initialize(&@responder : Mcp::Protocol::Request -> Mcp::Protocol::Message)
  end

  def initialize
    initialize do |request|
      id = request.id.not_nil!
      id_out : (String | Int64) = id.to_s

      case request.method
      when Mcp::Protocol::Methods::INITIALIZE
        Mcp::Protocol::Result.new(
          JSON.parse(%({
            "protocolVersion":"2024-11-05",
            "capabilities":{"tools":{"listChanged":true}},
            "serverInfo":{"name":"S","version":"0.1.0"}
          })),
          id_out
        )
      when Mcp::Protocol::Methods::TOOLS_LIST
        Mcp::Protocol::Result.new(
          JSON.parse(%({"tools":[{"name":"echo","description":"Echo","inputSchema":{"type":"object","properties":{},"required":[]}}]})),
          id_out
        )
      when Mcp::Protocol::Methods::TOOLS_CALL
        Mcp::Protocol::Result.new(
          JSON.parse(%({"content":[{"type":"text","text":"Hello"}]})),
          id_out
        )
      when Mcp::Protocol::Methods::RESOURCES_LIST
        Mcp::Protocol::Result.new(
          JSON.parse(%({"resources":[{"uri":"file://a.txt","name":"a","description":null,"mimeType":"text/plain"}]})),
          id_out
        )
      when Mcp::Protocol::Methods::RESOURCES_READ
        Mcp::Protocol::Result.new(
          JSON.parse(%({"contents":[{"uri":"file://a.txt","mimeType":"text/plain","text":"A"}]})),
          id_out
        )
      when Mcp::Protocol::Methods::PROMPTS_LIST
        Mcp::Protocol::Result.new(
          JSON.parse(%({"prompts":[{"name":"p","description":"P","arguments":[{"name":"topic","description":null,"required":true}]}]})),
          id_out
        )
      when Mcp::Protocol::Methods::PROMPTS_GET
        Mcp::Protocol::Result.new(
          JSON.parse(%({"description":"P","messages":[{"role":"user","content":"hi"}]})),
          id_out
        )
      when Mcp::Protocol::Methods::LOGGING_SET_LEVEL
        Mcp::Protocol::Result.new(JSON.parse(%({})), id_out)
      else
        Mcp::Protocol::Error.new(
          Mcp::Protocol::Error::ErrorData.new(Mcp::Protocol::Error::METHOD_NOT_FOUND, "no"),
          id_out
        )
      end
    end
  end

  def start
    @started = true
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
    when Mcp::Protocol::Notification
    else
    end
  end

  def inject(message : Mcp::Protocol::Message)
    @on_message.try &.call(message)
  end
end

describe Mcp::Client do
  it "starts the underlying transport" do
    transport = ClientMockTransport.new
    client = Mcp::Client.new(transport)
    client.start
    transport.started.should be_true
  end

  it "supports typed initialize with string id responses" do
    client = Mcp::Client.new(ClientMockTransport.new)
    res = client.connect_typed("c", "0.1.0")
    res.should be_a(Mcp::Types::InitializeResult)
    res.as(Mcp::Types::InitializeResult).server_info.name.should eq "S"
  end

  it "supports typed tools/list and tools/call" do
    client = Mcp::Client.new(ClientMockTransport.new)

    list = client.list_tools_typed
    list.should be_a(Mcp::Types::ToolsListResult)
    list.as(Mcp::Types::ToolsListResult).tools[0].name.should eq "echo"

    call = client.call_tool_typed("echo", {msg: "x"})
    call.should be_a(Mcp::Types::ToolCallResult)
    call.as(Mcp::Types::ToolCallResult).content[0].text.should eq "Hello"
  end

  it "supports typed resources and prompts helpers" do
    client = Mcp::Client.new(ClientMockTransport.new)

    resources = client.list_resources_typed
    resources.should be_a(Mcp::Types::ResourcesListResult)
    resources.as(Mcp::Types::ResourcesListResult).resources[0].uri.should eq "file://a.txt"

    read = client.read_resource_typed("file://a.txt")
    read.should be_a(Mcp::Types::ResourcesReadResult)
    read.as(Mcp::Types::ResourcesReadResult).contents[0].text.should eq "A"

    prompts = client.list_prompts_typed
    prompts.should be_a(Mcp::Types::PromptsListResult)
    prompts.as(Mcp::Types::PromptsListResult).prompts[0].name.should eq "p"

    get = client.get_prompt_typed("p", {topic: "x"})
    get.should be_a(Mcp::Types::PromptsGetResult)
    get.as(Mcp::Types::PromptsGetResult).messages[0].content.should eq "hi"
  end

  it "supports get_prompt_typed with JSON::Any arguments" do
    client = Mcp::Client.new(ClientMockTransport.new)

    args = JSON.parse(%({"topic":"x"}))
    get = client.get_prompt_typed("p", args)
    get.should be_a(Mcp::Types::PromptsGetResult)
    get.as(Mcp::Types::PromptsGetResult).messages[0].content.should eq "hi"
  end

  it "supports typed logging/setLevel" do
    client = Mcp::Client.new(ClientMockTransport.new)
    res = client.set_log_level_typed("debug")
    res.should be_a(Mcp::Types::EmptyResult)
  end

  it "responds to roots/list requests" do
    transport = ClientMockTransport.new
    client = Mcp::Client.new(transport)
    client.add_root("file:///repo", "repo")

    transport.inject(Mcp::Protocol::Request.new(Mcp::Protocol::Methods::ROOTS_LIST, nil, 1))

    last_msg = transport.sent_messages.last.as(Mcp::Protocol::Result)
    last_msg.result["roots"].as_a[0]["uri"].as_s.should eq "file:///repo"
  end

  it "uses on_roots_list handler when set" do
    transport = ClientMockTransport.new
    client = Mcp::Client.new(transport)

    client.on_roots_list do
      Mcp::Types::RootsListResult.new(roots: [Mcp::Types::Root.new(uri: "file:///x")])
    end

    transport.inject(Mcp::Protocol::Request.new(Mcp::Protocol::Methods::ROOTS_LIST, nil, 2))
    last_msg = transport.sent_messages.last.as(Mcp::Protocol::Result)
    last_msg.result["roots"].as_a[0]["uri"].as_s.should eq "file:///x"
  end

  it "invokes on_logging_message for logging/message notifications" do
    transport = ClientMockTransport.new
    client = Mcp::Client.new(transport)

    got = nil
    client.on_logging_message do |msg|
      got = msg.message
    end

    params = JSON.parse(%({"level":"info","message":"m","logger":"l"}))
    transport.inject(Mcp::Protocol::Notification.new(Mcp::Protocol::Methods::LOGGING_MESSAGE, params))
    got.should eq "m"
  end

  it "constructs logging message params payload" do
    payload = Mcp::Types::LoggingMessageParams.new(level: "info", message: "m", logger: nil)
    payload.level.should eq "info"
    JSON.parse(payload.to_json)["message"].as_s.should eq "m"
  end

  it "returns Protocol::Error when typed decode fails" do
    transport = ClientMockTransport.new do |request|
      id_out : (String | Int64) = request.id.not_nil!.to_s
      Mcp::Protocol::Result.new(JSON.parse(%({"not":"init"})), id_out)
    end
    client = Mcp::Client.new(transport)

    res = client.connect_typed("c", "0.1.0")
    res.should be_a(Mcp::Protocol::Error)
    res.as(Mcp::Protocol::Error).error.code.should eq Mcp::Protocol::Error::INTERNAL_ERROR
  end
end
