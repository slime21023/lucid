require "../protocol/messages"
require "../schema/builder"
require "../json_any"

module Mcp
  module ServerDSL
    # Runtime tool metadata used by `tools/list` and `tools/call`.
    struct ToolDefinition
      include JSON::Serializable
      property name : String
      property description : String
      property inputSchema : JSON::Any
      @[JSON::Field(ignore: true)]
      property handler : Proc(JSON::Any?, JSON::Any)?

      def initialize(@name, @description, @inputSchema, @handler)
      end
    end

    # Per-server tool registry (one instance per server subclass).
    class ToolRegistry
      def initialize
        @tools = Hash(String, ToolDefinition).new
      end

      def register(definition : ToolDefinition)
        @tools[definition.name] = definition
      end

      def []?(name : String)
        @tools[name]?
      end

      def values
        @tools.values
      end
    end

    # Macro to include the registry logic in the including class
    macro included
      # Use a class variable for the registry that is separate per subclass
      # Using 'inherited' hook to initialize it.
      macro inherited
        @@registry = ToolRegistry.new
        
        def self.registry
          @@registry
        end
      end
      
      # Base registry for pure Server instance usage (fallback)
      @@registry = ToolRegistry.new
      def self.registry
        @@registry
      end

      def registry
        self.class.registry
      end
    end

    # Registers a tool and generates:
    # - an args struct (`Args_<toolname>`) for JSON decoding
    # - a JSON schema for `tools/list`
    # - a handler wrapper for `tools/call`
    macro tool(name, description, **args, &block)
      {% begin %}
        # Generate a struct for arguments
        struct Args_{{name.id}}
          include JSON::Serializable
          {% for arg_name, arg_type in args %}
            property {{arg_name.id}} : {{arg_type}}
          {% end %}
        end

        # Generate JSON Schema
        
        # Unique method name to register this tool
        def self.register_tool_{{name.id}}
           schema_props = {} of String => String
           required = [] of String
           {% for arg_name, arg_type in args %}
             type_str = {{arg_type.stringify}}
             nilable = type_str.ends_with?("?")
             base_type_str = nilable ? type_str[0, type_str.size - 1] : type_str
             schema_props[{{arg_name.stringify}}] = Mcp::Schema::Builder.json_type_for(base_type_str)
             required << {{arg_name.stringify}} unless nilable
           {% end %}

            json_schema = Mcp::Schema::Builder.object(schema_props, required)
            
            handler_proc = ->(json_params : JSON::Any?) {
               if json_params
                 args_obj = Args_{{name.id}}.from_json(json_params.to_json)
               else
                 args_obj = Args_{{name.id}}.from_json("{}")
               end
               
               {% arg_var = block.args.empty? ? "args".id : block.args[0] %}
               {{arg_var}} = args_obj
               
               result = begin
                 {{block.body}}
               end
               Mcp::Json.to_any(result)
            }
            
            definition = ToolDefinition.new(
              name: {{name}}, 
              description: {{description}}, 
              inputSchema: json_schema, 
              handler: handler_proc
            )
            
            # @@registry is defined by the included macro hooks
            @@registry.register(definition)
        end
        
        # Call the registration immediately
        register_tool_{{name.id}}
      {% end %}
    end
  end
end
