require "rspec"
require 'flo'

describe "StepProcessor" do
  describe "#instance" do
    it "creates FloStepAction if responds to flo_step" do
      @proc_class = Class.new do
        def flo_step
          puts "New Processor!"
        end
      end
      action = StepAction.from_obj(@proc_class.new)
      action.should be_a_kind_of FloStepAction
    end
    it "creates a ProcAction if typeof Proc" do
      proc = -> { puts "hi" }
      action = StepAction.from_obj(proc)
      action.should be_kind_of ProcStepAction
      action.handler.should eql proc
    end
  end
  describe "ProcProcessor" do
    it "handles execute by running the proc" do
      foo = false
      bar = ->(input, ctx) { foo = true }
      action = StepAction.from_obj(bar)
      action.execute(nil, nil)
      foo.should be_true
    end
  end
end