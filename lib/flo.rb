## Placeholder for namespace?

# Public: Entry point into the flow library.  Flows can be created by instantiating an empty Flo and adding steps,
#  or by extending Flo and defining steps in the constructor
#

require 'flo/step_action'

module Flo
  class Flo

    attr_accessor :index, :ctx, :head, :cursor

    # ctx = member for flow-wide data
    # - flow
    #   - errors, info lists.
    # - step
    #   - status
    def initialize(options=nil)
      @index = { }
      @ctx = options || { flow: { }, step: { } }
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
      if next_target.is_a?(Hash) && next_target.size >= 1
        name = next_target.keys[0]
        if @index[name]
          raise "This flow already contains a named action #{name}"
        end
        step_key = name
        next_action = next_target.values[0]
        options = next_target
        #options.delete(step_key)
      else #target is an object to be executed
        next_action = next_target
        options = nil
      end

      step = FloStep.new(next_action, step_key, options)
      @head ||= step
      @cursor << step if @cursor # concat the step onto the last one
      @cursor = step
      @index[step.name] = step # Add into index by name
      self
    end

    ##
    # Wrap the last step in an iterating step, repeat until next action returns null
    def *
      @cursor = IteratingFloStep.new(@cursor.action, @cursor.name)
      @head = @cursor
      self
    end

    def start!(flo_init = nil)
      @ctx = flo_init if flo_init
      @cursor = @head
      @cursor.execute({ }, @ctx)
    end

  end


  ##
  # A node in the execution graph of a flo.  Keeps a StepAction and members to organize the action in the flo
  class FloStep

    ERROR = 'error'
    SUCCESS = 'success'

    attr_accessor :next_steps, :name, :action
    attr_reader :err_stop

    def initialize(action, name=nil, options=nil)
      @next_steps = []
      @action = StepAction.from_obj(action)
      @name = name || @action.name
      @err_stop = options && options[:err_stop] || false
    end

    def << (step)
      @next_steps << step
    end

    def execute(input, ctx)
      output = execute_action(input, ctx)
      # If the execution of the step results in another step, do that
      while output.kind_of?(FloStep) || output.respond_to?(:execute)
        output = output.execute(input, ctx)
      end
      # otherwise continue on down to the next step (should only be one I think)
      next_steps.each do |step|
        output = step.execute(output, ctx)
      end
    end

    def execute_action(input, ctx)
      output = action.execute(input, ctx)
      if @err_stop && ctx[:step][:status] == ERROR
        raise "Stop On Error" # TODO: create an exception and add handling
      end
      output
    end

    def status(ctx, stat)
      ctx[:step][:status] = stat
    end

  end

  ##
  # A FloStep that iterates on the contained action as long as output is not nil
  class IteratingFloStep < FloStep
    def execute(input, ctx)
      # while our iterable action continues to emit...
      while (output = action.execute(input, ctx)) do
        # send output down the line
        next_steps.each do |step|
          step.execute(output, ctx)
        end
      end
    end
  end

end

