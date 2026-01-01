require "./spec_helper"

class ClientMockTransport < Mcp::Transport::Base
  getter started = false

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
    case message
    when Mcp::Protocol::Request
      spawn do
        @on_message.try &.call(@responder.call(message))
      end
    when Mcp::Protocol::Notification
    else
    end
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
