require "./spec_helper"

describe Mcp::Transport do
  it "LineDelimited yields non-empty frames" do
    io = IO::Memory.new("x\n\n{\"jsonrpc\":\"2.0\",\"method\":\"y\"}\n")
    framing = Mcp::Transport::Framing::LineDelimited.new(io)
    frames = [] of String
    framing.each_frame { |f| frames << f }
    frames.size.should eq 2
  end

  it "Stdio reads frames, parses messages, and calls on_message" do
    input = IO::Memory.new(%(

{"jsonrpc":"2.0","method":"x","id":1}
{"jsonrpc":"2.0","nope":true}
{not json
{"jsonrpc":"2.0","result":{"ok":true},"id":"1"}
))
    output = IO::Memory.new
    transport = Mcp::Transport::Stdio.new(input, output)

    received = [] of Mcp::Protocol::Message
    transport.on_message = ->(m : Mcp::Protocol::Message) { received << m; nil }
    transport.start

    Fiber.yield
    Fiber.yield

    received.size.should eq 2
    received[0].should be_a(Mcp::Protocol::Request)
    received[1].should be_a(Mcp::Protocol::Result)
  end

  it "Stdio sends JSON-RPC messages" do
    input = IO::Memory.new("")
    output = IO::Memory.new
    transport = Mcp::Transport::Stdio.new(input, output)
    transport.send(Mcp::Protocol::Notification.new("ping"))
    output.to_s.includes?("\"method\":\"ping\"").should be_true
  end
end
