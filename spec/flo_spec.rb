require "rspec"
require "flo"

describe Flo do

  before(:each) do
    @flo = Flo::Flo.new
    @proc_class = Class.new do
      def flo_step(input, ctx)
        puts "New Processor!"
      end
    end
    @simple_proc_step = @proc_class.new
  end

  describe '#>> to chain steps' do

    before(:each) do
    end

    # >> MyHandler.new
    it "should add a step processor object to the index" do
      @flo >> @simple_proc_step
      #p @flo.graph
      @flo.index.should include({@flo.cursor.name => @flo.cursor})
    end

    # >> MyHandler1.new
    it "should add a step action object to the flow" do
      step = @simple_proc_step

      def step.name
        "Flo"
      end

      @flo >> step
      flo_step = @flo.index['Flo']
      flo_step.action.handler.should eql step
      flo_step.action.should be_kind_of FloStepAction

    end

    it "should not allow 2 actions with the same name" do
      expect { @flo >> {step1: @simple_proc_step} >> {step1: @simple_proc_step} }.should raise_error
    end
    it "should not allow 2 anonymous actions pointing to the same handler" do
      expect { @flo >> @simple_proc_step >> @simple_proc_step }.should_not raise_error
    end

    # >> handler_1 >> handler_2
    it "should add multiple processors to the graph" do

      @flo >> {step1: @simple_proc_step} >> {step2: @simple_proc_step}
      @flo.index[:step1].action.handler.should eql @simple_proc_step
      @flo.index[:step2].action.handler.should eql @simple_proc_step
    end

    # >> ->(input, ctx) {...}
    it "should add lambdas" do
      @flo >> ->(input, ctx) { x = 1 + 1 }
      p @flo.index
      found = @flo.index.values.find { |obj|
        obj.name =~ /<proc>/
      }
      found.should_not be_nil
      found.action.should be_kind_of ProcStepAction
    end
    # >> { my_step1: step, err_stop: true }
    it "should add stop actions" do
      @flo >> { my_step1: step, err_stop: true }

    end

    ##
    # self >> my_step1: MyHandler1.new >> my_step2: MyHandler2.new
    # self >> my_step1: MyHandler1.new, err_stop: true >> my_step2: MyHandler2.new
    # self >> my_step1: MyHandler1.new, on_err: ->(step, ctx) {...}, err_stop: true >> my_step2: MyHandler2.new
    #                1

  end

  describe "#start!" do
    it "should call flo_step on the first step" do
      @flo >> @simple_proc_step
      @simple_proc_step.should_receive(:flo_step)
      @flo.start!
    end

    it "should pass empty input" do
      passed_input = nil
      @flo >> ->(input, ctx) { passed_input = input }
      @flo.start!
      passed_input.should be_empty
    end

    describe "with 2 steps" do
      # self >> my_step1: MyHandler1.new >> my_step2: MyHandler2.new
      describe " >> step_one >> step_two" do
        before do
          @passed_input = nil
          @flo >> ->(input, ctx) { {my_data: 'hello!'} } >> ->(input, ctx) { @passed_input = input }
          @flo.start!
        end
        describe "should pass results from first step into second" do
          specify { @passed_input.should_not be_empty }
          specify { @passed_input[:my_data].should eql 'hello!' }
        end
      end

      # self >> {my_step1: MyHandler1.new, err_stop: true} >> my_step2: MyHandler2.new
      describe "ERR_STOP: >> my_step1: MyHandler1.new, err_stop: true >> step_two" do
        before do
          step = @simple_proc_step
          def step.execute(input, ctx)
            status(ctx, FloStep::ERROR)
            input
          end
          @step2 = @proc_class.new
          @flo >> { my_step1: step, err_stop: true } >> @step2
          @flo.start!
        end
        it "should stop on error status" do
          @step2.should_not_receive :execute
        end
      end
    end
  end

  describe Flo::FloStep do
    before do
      @flo = Flo::Flo.new
    end

    context "#execute" do
      before do
        @proc_return
        @flo >> ->(input, ctx) do
          # Example of conditional logic that returns a FloStep
          if true
            Flo::FloStep.new(->(i, c) { @proc_return = 'hello!' })
          end
        end
        @flo.start!
      end

      it "should execute the return of a step, if return itself is a FloStep" do
        @proc_return.should eql 'hello!'
      end
    end
  end

end