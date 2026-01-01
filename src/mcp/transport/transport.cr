require "../protocol/messages"

module Mcp
  module Transport
    # Base transport for MCP message IO.
    #
    # Implementations are responsible for reading raw frames (e.g. lines),
    # parsing them into `Mcp::Protocol::Message`, and writing outgoing messages.
    abstract class Base
      # Callback for when a message is received
      property on_message : (Protocol::Message -> Nil)?

      # Starts the transport (usually starts a read loop)
      abstract def start

      # Sends a message
      abstract def send(message : Protocol::Message)

      # Closes the transport
      abstract def close
    end
  end
end
