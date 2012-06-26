require "rspec"
require "flo"

describe Flo::Flo do

  before(:each) do
    @flo = Flo::Flo.new
    @proc_class = Class.new do
      def flo_step
        puts "New Processor!"
      end
    end
    @simple_proc_step = @proc_class.new
  end

  describe '>' do

    before(:each) do
    end

    it "should add a step processor object to the graph with a default key" do
      @flo >> @simple_proc_step
      #p @flo.graph
      @flo.graph.should include(0 => @simple_proc_step)
    end

    it "should add a step processor object to the graph with a name key" do
      step = class << @simple_proc_step
        def name
          "Flo"
        end
      end

      @flo >> step
      #p @flo.graph
      @flo.graph.should include("0-Flo" => step)
    end

    it "should add multiple processors to the graph" do

      @flo >> @simple_proc_step >> @simple_proc_step
      #p @flo.graph
      @flo.graph.should include(0 => @simple_proc_step)
      @flo.graph.should include(1 => @simple_proc_step)
    end

    it "should add lambdas" do
      @flo >> -> {x = 1 + 1}
      @flo.graph.should include("0-<proc>")
    end
  end

  describe "start!" do
    it "should call flo_step on the first step" do
      @flo >> @simple_proc_step
      @simple_proc_step.should_receive(:flo_step)
      @flo.start!
    end
  end

  describe "walk_graph" do
    it "should walk the graph in order" do
      #@flo >> @simple_proc_step >> [(-> {x = false}), @proc_class.new]
    end
  end

  describe "do_step" do
    it "should call flo_step if implemented"
    it "should execute a Proc that takes 2 args as if it were flo_step"
    if "should execuate a Proc with no args to get the next node" #TODO Should this be in walk_graph?
  end
end