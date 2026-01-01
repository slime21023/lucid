module Mcp
  module Transport
    module Framing
      # Reads non-empty lines from an IO as message frames.
      class LineDelimited
        def initialize(@io : IO)
        end

        def each_frame(&block : String ->)
          @io.each_line do |line|
            next if line.blank?
            yield line
          end
        end
      end
    end
  end
end
