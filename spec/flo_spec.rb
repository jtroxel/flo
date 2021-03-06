require "rspec"
require "flo"

describe Flo do

  attr :flo, :simple_proc

  let(:flo) { Flo::Flo.new }

  let(:proc_class) do
    Class.new do
      def execute(input, ctx)
        puts "New Processor!"
        input
      end
    end
  end
  let(:simple_proc) { proc_class.new }

  let(:it_class) do
    Class.new {
      def execute(input, ctx, &block)
        (1..5).each do |count|
          block.yield(count)
        end
      end
    }
  end
  let(:iterator) { it_class.new }

  describe '#>> to chain steps' do

    before(:each) do
    end

    # >> MyHandler.new
    it "should add a step processor object to the index" do
      flo >> simple_proc
      flo.index.should include({ flo.cursor.name => flo.cursor })
    end

    # >> MyHandler1.new
    it "should add a step action object to the flow" do
      step = simple_proc

      def step.name
        "Flo"
      end

      flo >> step
      flo_step = flo.index['Flo']
      flo_step.action.processor.should eql step
      flo_step.action.should be_kind_of Flo::StepAction

    end

    it "should not allow 2 actions with the same name" do
      expect { flo >> { step1: simple_proc } >> { step1: simple_proc } }.should raise_error
    end
    it "should not allow 2 anonymous actions pointing to the same handler" do
      expect { flo >> simple_proc >> simple_proc }.should_not raise_error
    end

    # >> handler_1 >> handler_2
    it "should add multiple processors to the graph" do

      flo >> { step1: simple_proc } >> { step2: simple_proc }
      flo.index[:step1].action.processor.should eql simple_proc
      flo.index[:step2].action.processor.should eql simple_proc
    end

    # >> ->(input, ctx) {...}
    it "should add lambdas" do
      flo >> ->(input, ctx) { x = 1 + 1 }
      p flo.index
      found = flo.index.values.find { |obj|
        obj.name =~ /<proc>/
      }
      found.should_not be_nil
      found.action.should be_kind_of Flo::ProcStepAction
    end
    # >> { my_step1: step, err_stop: true }
    it "should add stop actions" do
      flo >> { my_step1: simple_proc, err_stop: true }
      # TODO
    end

  end

  # { blah: doit } * >> {}
  describe '#* to mark previous step as an iterator' do

    it "should create an IteratingFloStep" do
      (flo >> { my_step1: iterator }).*
      flo.cursor.should be_a_kind_of Flo::IteratingFloStep
    end

  end

  describe "#start!" do
    it "should call flo_step on the first step" do
      flo >> simple_proc
      simple_proc.should_receive(:execute)
      flo.start!
    end

    it "should pass empty input" do
      passed_input = nil
      flo >> ->(input, ctx) { passed_input = input }
      flo.start!
      passed_input.should be_empty
    end

    describe "with 2 steps" do
      # self >> my_step1: MyHandler1.new >> my_step2: MyHandler2.new
      describe " >> step_one >> step_two" do
        before do
          @passed_input = nil
          flo >> ->(input, ctx) { { my_data: 'hello!' } } >> ->(input, ctx) { @passed_input = input }
          flo.start!
        end
        describe "should pass results from first step into second" do
          specify { @passed_input.should_not be_nil }
          specify { @passed_input[:my_data].should eql 'hello!' }
        end
      end

      # self >> {my_step1: MyHandler1.new, err_stop: true} >> my_step2: MyHandler2.new
      describe "ERR_STOP: >> my_step1: MyHandler1.new, err_stop: true >> step_two" do
        before do
          step = simple_proc

          @action2 = proc_class.new
          flo >> { my_step1: ->(input, ctx) { ctx[:step][:status] = 'error' }, err_stop: true } >> { my_step2: @action2 }
          # Stuff an error status into the context
          #flo.head.set_status(flo.ctx, Flo::FloStep::ERROR)
          @step2 = flo.cursor
        end
        it "should stop on error status" do
          #expect { flo.start! }.to raise_error
          @step2.should_not_receive :perform
          flo.start!
        end
      end
      context "with IteratingStep" do
        it "should iterate calling next step" do
          call_count = 0
          (flo >> { my_step1: iterator }).* >> ->(input, ctx) {
            call_count += 1
          }
          flo.start!
          call_count.should eql 6 # 5 iterations plus the nil signal
        end
      end
      # TODO: rewrite this betterspecs style
      context "with CollectingStep" do
        it "should buffer output of previous step" do
          call_count = 0
          output = nil
          flo.from({ my_step1: iterator })
          .send_each
          .collect(5)
          .to ->(input, ctx) {
            call_count += 1
            output = input
          }

          flo.start!
          call_count.should eql 2 # Iterator sends nil when done
          output.should be_a Array
          output.size.should eql 5
        end
      end
    end
  end

  describe Flo::FloStep do
    before do
      flo = Flo::Flo.new
    end

    context "#initialize" do
      before do
        @step = Flo::FloStep.new(proc_class.new, "step name", { err_stop: true })
      end

      specify { @step.err_stop.should be_true }
      specify { @step.name.should eql "step name" }
    end

    context "#execute" do
      before do
        @proc_return
        flo >> ->(input, ctx) do
          # Example of conditional logic that returns a FloStep
          if true
            Flo::FloStep.new(->(i, c) { @proc_return = 'hello!' })
          end
        end
        flo.start!
      end

      it "should execute the return of a step, if return itself is a FloStep" do
        @proc_return.should eql 'hello!'
      end
    end
  end

end