require "./transport"
require "json"
require "../protocol/message_parser"
require "./framing/line_delimited"

module Mcp
  module Transport
    # Line-delimited JSON transport over STDIN/STDOUT (or any provided IOs).
    class Stdio < Base
      def initialize(@in : IO = STDIN, @out : IO = STDOUT)
        @framing = Framing::LineDelimited.new(@in)
      end

      def start
        # Start a read loop in a new fiber to avoid blocking
        spawn do
          read_loop
        end
      end

      def send(message : Protocol::Message)
        @out.puts(message.to_json)
        @out.flush
      end

      def close
        # In stdio, we typically don't close STDIN/STDOUT explicitly 
        # unless we want to terminate everything, but we can stop reading.
      end

      private def read_loop
        @framing.each_frame do |frame|
          begin
            message = Protocol::MessageParser.parse(frame)
            @on_message.try &.call(message) if message
          rescue ex
            # Log error or send error response back if malformed
            # For now, we silently ignore or write to stderr
            STDERR.puts "Error parsing message: #{ex.message}"
          end
        end
      end
    end
  end
end
