module Flo
  class XmlEmitter
    require "saxerator"

    ##
    # filename = xml file to parse
    # tag = symbolized name of the tag to enumerate
    def initialize(filename, tag)
      @filename = filename
      @options = {:headers => :first_row, :row_sep => :auto}.merge(options)
      @parser = Saxerator.parser(File.new(filename))
    end

    def execute(input, ctx)
      @parser.for_tag(tag.to_sym).each  do |row|
        yield row
      end
    end
  end
end