require "./transport"
require "../protocol/message_parser"
require "./framing/line_delimited"
require "socket"

module Mcp
  module Transport
    # Line-delimited JSON transport over a TCP socket.
    #
    # This uses the same framing as `Transport::Stdio` (one JSON message per line).
    #
    # Example (client side):
    # ```
    # transport = Mcp::Transport::Tcp.connect("127.0.0.1", 3333)
    # client = Mcp::Client.new(transport)
    # client.start
    # ```
    #
    # Example (server side, single connection):
    # ```
    # server = TCPServer.new("127.0.0.1", 3333)
    # transport = Mcp::Transport::Tcp.accept(server)
    # mcp = MyServer.new(transport)
    # mcp.start
    # ```
    class Tcp < Base
      def initialize(@socket : TCPSocket)
        @framing = Framing::LineDelimited.new(@socket)
      end

      def self.connect(host : String, port : Int32) : self
        new(TCPSocket.new(host, port))
      end

      # Convenience helper for servers that accept a single connection.
      def self.accept(server : TCPServer) : self
        new(server.accept)
      end

      def start
        spawn do
          read_loop
        end
      end

      def send(message : Protocol::Message)
        @socket.puts(message.to_json)
        @socket.flush
      end

      def close
        @socket.close
      end

      private def read_loop
        @framing.each_frame do |frame|
          begin
            message = Protocol::MessageParser.parse(frame)
            @on_message.try &.call(message) if message
          rescue ex
            STDERR.puts "Error parsing message: #{ex.message}"
          end
        end
      end
    end
  end
end
