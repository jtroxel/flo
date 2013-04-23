module Flo::Processor
  class FixedFieldEmitter

    #def initialize(filename, options)
    #  @filename = filename
    #  @options = options #{:headers => :first_row, :row_sep => :auto}.merge(options)
    #end

    def initialize(headers, field_lengths, filename)
      @headers = headers
      @lengths = field_lengths
      @filename = filename
    end

    def execute(input, ctx)
      File.foreach(@filename) do |row|
        field_pattern = "A#{@lengths.join('A')}"
        map = HashWithIndifferentAccess.new
        row_arr = row.unpack(field_pattern)
        @headers.each_with_index do |f, i|
          map[@headers[i].downcase] = row_arr[i]
        end
        yield map
      end
    end
  end
end