require "json"
require "../json_any"

module Mcp
  module Schema
    # Minimal JSON Schema builder for tool input schemas.
    module Builder
      def self.json_type_for(crystal_type : String) : String
        case crystal_type
        when "Int8", "Int16", "Int32", "Int64", "UInt8", "UInt16", "UInt32", "UInt64"
          "number"
        when "Float32", "Float64"
          "number"
        when "Bool"
          "boolean"
        when "String"
          "string"
        else
          "string"
        end
      end

      def self.object(properties : Hash(String, String), required : Array(String)) : JSON::Any
        schema_props = {} of String => Hash(String, String)
        properties.each do |name, type|
          schema_props[name] = {"type" => type}
        end

        schema = {
          "type"       => "object",
          "properties" => schema_props,
          "required"   => required,
        }

        Mcp::Json.to_any(schema)
      end
    end
  end
end
