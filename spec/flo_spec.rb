require "rspec"
require "flo"

describe Flo do

  before(:each) do
    @flo = Flo::Flo.new
    @proc_class = Class.new do
      def flo_step
        puts "New Processor!"
      end
    end
    @simple_proc_step = @proc_class.new
  end

  describe '>> to chain steps' do

    before(:each) do
    end

    # >> MyHandler.new
    it "should add a step processor object to the graph" do
      @flo >> @simple_proc_step
      #p @flo.graph
      @flo.index.should include({@flo.tail.name => @flo.tail})
    end

    # >> my_step1: MyHandler1.new
    it "should add a step action object to the graph with a name key" do
      step = @simple_proc_step

      def step.name
        "Flo"
      end

      @flo >> step
      @flo.index['Flo'].action.handler.should eql step
    end

    it "should not allow 2 actions with the same name" do
      expect {@flo >> {step1: @simple_proc_step} >> {step1: @simple_proc_step}}.should raise_error
    end
    it "should not allow 2 anonymous actions pointing to the same handler" do
      expect {@flo >> @simple_proc_step >> @simple_proc_step}.should_not raise_error
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
      p found
      found.should_not be_nil
    end

    ##
    # self >> my_step1: MyHandler1.new >> my_step2: ->(step, ctx) {...}
    # self >> my_step1: MyHandler1.new, err_stop: true >> my_step2: ->(step, ctx) {...}
    # self >> my_step1: MyHandler1.new, on_err: ->(step, ctx) {...}, err_stop: true
    #                1

  end

  describe "start!" do
    it "should call flo_step on the first step" do
      @flo >> @simple_proc_step
      @simple_proc_step.should_receive(:flo_step)
      @flo.start!
    end
  end


  # Some other scenarios
  # self >> ProcessorReadLines.new(file) >> ->(step){ step.status == StepAction::ERROR ? flo >> HandleReadError.new >> stop} >> @process_csv_line

  # flo(:log_error_and_stop) >> handle_error: HandleReadError.new >> stop
  # self >> file_reader: ProcessorReadLines.new(file) >> check_status: ->(step){ step.status == Step::ERROR ? go(:log_error_and_stop)} >> add_row: @process_csv_line
  # self >> ProcessorReadLines.new(file).on_err(HandleReadError.new).stop >> @process_csv_line


end