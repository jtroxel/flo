module Flo
  # Module to mix in methods for handling chunks (of rows)
  module ChunkHandler

    ##
    # Split an array of input, execute each, and combine output into a new array
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