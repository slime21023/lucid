module Mcp
  module Protocol
    # Helpers for JSON-RPC ids (String or Int64).
    module Id
      def self.key(id : (String | Int64 | Nil)) : String?
        return nil if id.nil?
        case id
        when String
          id
        else
          id.to_s
        end
      end
    end
  end
end
