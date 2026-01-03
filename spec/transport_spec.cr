require "./spec_helper"
require "base64"
require "digest/sha1"

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

  it "Tcp connect/accept exchanges line-delimited JSON messages" do
    tcp_server = TCPServer.new("127.0.0.1", 0)
    port = tcp_server.local_address.as(Socket::IPAddress).port

    received = Channel(Mcp::Protocol::Message).new
    accepted = Channel(Mcp::Transport::Tcp).new

    spawn do
      transport = Mcp::Transport::Tcp.accept(tcp_server)
      transport.on_message = ->(m : Mcp::Protocol::Message) { received.send(m); nil }
      transport.start
      accepted.send(transport)
    end

    client_transport = Mcp::Transport::Tcp.connect("127.0.0.1", port)
    server_transport = accepted.receive

    client_transport.send(Mcp::Protocol::Notification.new("ping"))
    msg = received.receive
    msg.should be_a(Mcp::Protocol::Notification)
    msg.as(Mcp::Protocol::Notification).method.should eq "ping"

    client_transport.close
    server_transport.close
    tcp_server.close
  end

  it "WebSocket transport can be constructed over an IO" do
    io = IO::Memory.new
    ws = HTTP::WebSocket.new(io)
    transport = Mcp::Transport::WebSocket.new(ws)

    transport.on_message = ->(_m : Mcp::Protocol::Message) { nil }
    transport.start
    transport.send(Mcp::Protocol::Notification.new("ping"))
    transport.close
  end

  it "WebSocket.connect performs a client handshake" do
    tcp_server = TCPServer.new("127.0.0.1", 0)
    port = tcp_server.local_address.as(Socket::IPAddress).port

    done = Channel(Nil).new
    spawn do
      socket = tcp_server.accept

      raw = socket.gets("\r\n\r\n").to_s
      headers = {} of String => String
      raw.split("\r\n").each do |line|
        next if line.includes?("HTTP/")
        break if line.empty?
        if idx = line.index(':')
          headers[line[0, idx].strip] = line[idx + 1, line.size - idx - 1].strip
        end
      end

      key = headers["Sec-WebSocket-Key"]
      accept = Base64.strict_encode(Digest::SHA1.digest("#{key}258EAFA5-E914-47DA-95CA-C5AB0DC85B11"))

      socket << "HTTP/1.1 101 Switching Protocols\r\n"
      socket << "Upgrade: websocket\r\n"
      socket << "Connection: Upgrade\r\n"
      socket << "Sec-WebSocket-Accept: #{accept}\r\n"
      socket << "\r\n"
      socket.flush

      socket.close
      done.send(nil)
    end

    transport = Mcp::Transport::WebSocket.connect(URI.parse("ws://127.0.0.1:#{port}/"))
    transport.close

    done.receive
    tcp_server.close
  end
end
