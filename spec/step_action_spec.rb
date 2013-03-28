require "rspec"
require 'flo'

describe "StepAction" do
  describe "#from_obj" do
    it "creates StepAction if responds to flo_step" do
      @proc_class = Class.new do
        def execute
          puts "New Processor!"
        end
      end
      action = Flo::StepAction.from_obj(@proc_class.new)
      action.should be_a_kind_of Flo::StepAction
    end

    it "creates a ProcAction if typeof Proc" do
      proc = -> { puts "hi" }
      action = Flo::StepAction.from_obj(proc)
      action.should be_kind_of Flo::ProcStepAction
      action.processor.should eql proc
    end
  end

  describe "ProcStepAction" do
    describe "#execute" do
      it "runs the proc" do
        foo = false
        bar = ->(input, ctx) { foo = true }
        action = Flo::StepAction.from_obj(bar)
        action.execute(nil, nil)
        foo.should be_true
      end
    end
  end
end