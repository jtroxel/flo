## Placeholder for namespace?

# Public: Entry point into the flow library.  Flows can be created by instantiating an empty Flo and adding steps,
#  or by extending Flo and defining steps in the constructor
#

require 'flo/step_action'

module Flo
  class Flo

    attr_accessor :index, :step, :ctx, :head, :cursor

    # ctx = member for flow-wide data
    # - flow
    #   - errors, info lists.
    #   - status
    def initialize(options=nil)
      @index = {}
      @ctx = options || {}
      @head # First step
      @cursor # last step, either added or executed depending
    end

    ##
    # Add a flow step into the graph
    # === OPTIONS
    # - next_target is a hash of one, use the symbol as the name of the step and add to the index, value is the action
    #   e.g.:  >> read_file: FileReader.new
    #
    # - next_target is an object, either a Proc or an implementer of flo_step(step, flo)
    #
    def >>(next_target)
      if (next_target.is_a?(Hash) && next_target.size) == 1
        name = next_target.keys[0]
        if @index[name]
          raise "This flow already contains a named action #{name}"
        end
        step_key = name
        next_target = next_target.values[0]
      end

      step = FloStep.new(next_target, step_key)
      @head ||= step
      @cursor << step if @cursor # concat the step onto the last one
      @cursor = step
      @index[step.name] = step # Add into index by name
      self
    end

    def start!(flo_init = nil)
      @ctx = flo_init if flo_init
      @cursor = @head
      @cursor.execute({}, @ctx)
    end

  end


  class FloStep

    attr_accessor :next_steps, :name, :action

    def initialize(action, name=nil)
      @next_steps = []
      @action = StepAction.from_obj(action)
      @name = name || @action.name
    end

    def << (step)
      @next_steps << step
    end

    def execute(input, ctx)
      output = action.execute(input, ctx)
      # If the execution of the step results in another step, do that
      while output.kind_of?(FloStep) || output.respond_to?(:execute)
        output = output.execute(input, ctx)
      end
      next_steps.each do |step|
        output = step.execute(output, ctx)
      end
    end

  end
end

