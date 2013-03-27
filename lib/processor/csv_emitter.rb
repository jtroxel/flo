module Flo
  class CsvEmitter
    require "csv"

    def initialize(filename, options)
      @filename = filename
      @options = {:headers => :first_row, :row_sep => :auto}.merge(options)
    end

    def execute(input, ctx)
      CSV.foreach(@filename, @options) do |row|
        yield row
      end
    end
  end
end