require "rspec"
require "flo"
require 'flo/processor/xml_emitter'

describe Flo::Processor::XmlEmitter do
  let(:yielded) { [] }
  let(:processor) { Proc.new {|row| yielded << row } }
  subject { Flo::Processor::XmlEmitter.new('./spec/fixtures/four_item.xml', "Item") }
  it "should call the block with each found tag" do
    subject.execute(nil, {}, &processor)
    yielded.size.should eql 4
    yielded[3].keys[0].should eql 'SubItem'
  end
end
