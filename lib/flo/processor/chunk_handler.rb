module Flo
  module ChunkHandler
    def handle_chunk(input, ctx)
      output = []
      if (input.kind_of? Array)
        input.each do |el|
          o = execute(el, ctx)
          output << o if o # Processes that handle chunks can skip a row by returning nil
        end
        output
      else
        nil
      end
    end
  end
end