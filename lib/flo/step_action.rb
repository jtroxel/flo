module Flo
##
# A StepAction generally wraps an object (handler) )that acts on flow data.  The contract for StepAction consists of the following
# - execute: perform whatever on the flow/step data, invoke the handler
# - name: generate a unique name for the action
#

  class StepAction

    def self.from_obj(processor)
      return processor if processor.kind_of? StepAction # Already wrapped
      #return IteratingStepAction.new(processor) if processor.respond_to?(:execute) # TODO check signature?
      return ProcStepAction.new(processor) if processor.kind_of? Proc
      return StepAction.new(processor) if processor.respond_to?(:execute) # TODO check signature?
      raise ArgumentError.new "can't create a StepAction from #{processor.inspect}"
    end

    attr_accessor :processor

    def initialize(proc)
      @processor = proc
    end

    def execute(input, ctx)
      @processor.execute(input, ctx)
    end

    def name
      if @processor.respond_to?(:name)
        return @processor.name
      end
      self.object_id
    end

  end

##
# a StepAction that invokes a proc
  class ProcStepAction < StepAction

    def execute(input, ctx)
      @processor.call(input, ctx)
    end

    def name
      "#{object_id}-<proc>"
    end
  end

##
# An iterating action:  yields to a block until done
  class IteratingStepAction < StepAction
    def execute(input, ctx, &block)
      @processor.execute(input, ctx, &block)
    end
  end
end