require "../src/lucid"

# Define the Math Server
class MathServer < Mcp::Server
  tool("add", "Adds two numbers", a: Int32, b: Int32) do |args|
    args.a + args.b
  end

  tool("concat", "Concatenates strings", first: String, second: String) do |args|
    "#{args.first}#{args.second}"
  end
end

# Create standard IO transport
transport = Mcp::Transport::Stdio.new

# Create and start server
server = MathServer.new(transport)

STDERR.puts "Starting Math Server..."
server.start
