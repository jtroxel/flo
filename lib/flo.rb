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
      @index = {}
      @ctx = options || { flow: {}, step: {} }
      @head # First step
      @cursor # last step, either added or executed depending
    end

    ##
    # Add a flow step into the graph
    # TODO:  I hate this "operator," but => and -> are taken. 'to' might be easier to read but not as pseudo-graphical
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
      add_step(step) # Add into index by name
      self
    end

    alias_method :to, :>> # { my_step: some_processor }.to { some_other_step: some_other_processor }

    def add_step(step)
      @head ||= step
      @cursor << step if @cursor # concat the step onto the last one
      @cursor = step
      @index[step.name] = step
    end

    def from(next_target)
      unless @head.nil?
        raise "flo already has a first step"
      end
      self >> next_target
      self
    end

    ##
    # collect count outputs from the previous step and then send to the next step
    def collect(count, name=nil)
      add_step(CollectingFloStep.new(count, name || "collect-#{@index.size}"))
      self
    end

    ##
    # Wrap the last step in an iterating step, repeat until next action returns null
    def *
      old = @cursor
      @cursor = IteratingFloStep.new(@cursor.action.processor, @cursor.name)
      @head = @cursor if @head == old
      self
    end

    alias_method :send_each, :* # { my_step: some_iterating_processor }.send_each.to { some_other_step: some_other_processor }

    def start!(flo_init = nil)
      @ctx = flo_init if flo_init
      @cursor = @head
      @cursor.perform({}, @ctx)
    end

  end


  ##
  # A node in the execution graph of a flo.  Keeps a StepAction and members to organize the action in the flo
  class FloStep

    RUNNING = 'running'
    ERROR = 'error'
    SUCCESS = 'success'

    attr_accessor :next_steps, :name, :action, :err_stop, :on_err, :stop

    def initialize(processor, name=nil, options=nil)
      self.action = StepAction.from_obj(processor)
      self.stop = false
      init_step(name, options)
    end

    def init_step(name, options)
      self.next_steps = []
      self.name = name || @action.name
      self.err_stop = options && options[:err_stop] || false
      if options && options[:on_err]
        self.err_stop = true
        self.on_err = options[:on_err]
      end
    end

    def stop?
      stop
    end

    def << (step)
      @next_steps << step
    end

    ##
    # Perform the step's action
    # TODO:  should ctx be an object wrapping hash with methods that hide the structure of the data?
    def perform(input, ctx)
      begin
        output = execute_action(input, ctx) if input # Only execute with input.  TODO better signal for done
          # If exceptions are not handled in the processor...
      rescue => e
        puts e.message
        puts e.backtrace[0..15].join("\n")
      end

      return nil if stop?

      # If the execution of the step results in another step, do that.  for conditional next steps
      while output.kind_of?(FloStep) || output.respond_to?(:perform)
        output = output.perform(input, ctx)
      end
      # otherwise continue on down to the next step (should only be one I think)
      output = perform_all(output, ctx)
      output
    end

    def perform_all(input, ctx)
      output = input
      next_steps.each do |step|
        output = step.perform(output, ctx)
      end
      output
    end

    def execute_action(input, ctx)
      reset(ctx)

      output = action.execute(input, ctx)
      if @err_stop && status(ctx) == ERROR
        self.stop = true
        if on_err
          on_err.call(output, ctx)
        else
          raise "Stop On Error" # TODO: create an exception and add handling
        end
      end
      output
    end

    def reset(ctx)
      set_status(ctx, RUNNING)
      ctx[:step][:status_message] = nil
      ctx[:step][:errors] = nil
      self.stop = false
    end

    def set_status(ctx, stat)
      ctx[:step][:status] = stat
    end

    def status(ctx)
      ctx[:step][:status]
    end

  end

  ##
  # A FloStep that iterates on the contained action as long as output is not nil
  class IteratingFloStep < FloStep
    def initialize(processor, name=nil, options=nil)
      @action = IteratingStepAction.new(processor)
      init_step(name, options)
    end

    def perform(input, ctx)
      # iterable action emits to the block
      action.execute(input, ctx) do |output|
        # send each output down the line
        perform_all(output, ctx)
      end
      # Send nil down the line.  TODO:  create done signal?
      perform_all(nil, ctx)
    end
  end

  ##
  # A FloStep that collects outputs
  # TODO:  how to handle leftovers...  iterators will just stop calling next steps and we'll have junk in the buffer
  #          Maybe a Flo needs to call flo_done or something on all participants that receive it
  class CollectingFloStep < FloStep
    def initialize(count, name=nil, options=nil)
      @buffer = []
      @buffer_size = count
      init_step(name, options)
    end

    def perform(input, ctx)
      if @buffer.size < @buffer_size && input
        @buffer << input
      end
      if @buffer.size == @buffer_size || input.nil?
        next_steps.each do |step|
          step.perform(@buffer, ctx)
        end
        @buffer = []
      end
    end
  end
end

