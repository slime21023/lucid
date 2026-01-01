require "json"

module Mcp
  module Json
    def self.to_any(obj : JSON::Serializable) : JSON::Any
      JSON.parse(obj.to_json)
    end

    def self.to_any(value) : JSON::Any
      JSON.parse(value.to_json)
    end
  end
end
