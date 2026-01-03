require "./transport"
require "../protocol/message_parser"
require "http/web_socket"

module Mcp
  module Transport
    # JSON transport over WebSocket (each WS text frame is a full JSON-RPC message).
    #
    # Example:
    # ```
    # transport = Mcp::Transport::WebSocket.connect(URI.parse("ws://127.0.0.1:3333/mcp"))
    # client = Mcp::Client.new(transport)
    # client.start
    # ```
    class WebSocket < Base
      def initialize(@ws : HTTP::WebSocket)
      end

      def self.connect(uri : URI) : self
        new(HTTP::WebSocket.new(uri))
      end

      def start
        @ws.on_message do |frame|
          begin
            message = Protocol::MessageParser.parse(frame)
            @on_message.try &.call(message) if message
          rescue ex
            STDERR.puts "Error parsing message: #{ex.message}"
          end
        end

        spawn do
          begin
            @ws.run
          rescue
            # ignore connection errors on shutdown
          end
        end
      end

      def send(message : Protocol::Message)
        @ws.send(message.to_json)
      end

      def close
        @ws.close
      end
    end
  end
end
