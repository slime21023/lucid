require "json"
require "./messages"

module Mcp
  module Protocol
    # Best-effort parsing for line-delimited JSON-RPC messages.
    # Returns `nil` for unknown or malformed input.
    module MessageParser
      def self.parse(line : String) : Protocol::Message?
        any = JSON.parse(line)

        if any["method"]?
          if any["id"]?
            Protocol::Request.from_json(line)
          else
            Protocol::Notification.from_json(line)
          end
        elsif any["error"]?
          Protocol::Error.from_json(line)
        elsif any["result"]?
          Protocol::Result.from_json(line)
        else
          nil
        end
      rescue
        nil
      end
    end
  end
end
