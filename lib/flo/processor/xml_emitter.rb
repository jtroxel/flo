module Flo::Processor
  require 'saxerator'
  class XmlEmitter

    def name
      'row emitter XML'
    end

    ##
    # filename = xml file to parse
    # tag = symbolized name of the tag to enumerate
    def initialize(filename, tag)
      @tag = tag
      @filename = filename
      @parser = Saxerator.parser(File.new(filename))
    end

    def execute(input, ctx)
      @parser.for_tag(@tag.to_sym).each do |row|
        if block_given?
          yield row
        end
      end
    end
  end
end