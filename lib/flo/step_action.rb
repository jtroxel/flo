# Internal: Abstract class for step processors, factory
#
# A StepAction generally wraps an object (handler) )that acts on flow data.  The contract for StepAction consists of the following
# - execute: perform whatever on the flow/step data, invoke the handler
# - name: generate a unique name for the action
#

class StepAction
  attr_accessor :handler

  def initialize(proc)
    @handler = proc
  end

  def self.from_obj(action)
    return action if action.kind_of? StepAction # Already wrapped
    return FloStepAction.new(action) if action.respond_to?(:flo_step) # TODO check signature?
    return ProcStepAction.new(action) if action.kind_of? Proc
    raise ArgumentError.new "can't create a StepAction from #{action.inspect}"
  end

  def execute(input, ctx)
    raise "implement .execute in subclass"
  end

  def name
    if @handler.respond_to?(:name)
      return @handler.name
    end
    self.object_id
  end

end

##
# a StepAction that wraps a hendler that responds to flo_step
class FloStepAction < StepAction

  def execute(input, ctx)
    @handler.flo_step(input, ctx, self)
  end
end

##
# a StepAction that invokes a proc
class ProcStepAction < FloStepAction

  def execute(input, ctx)
    @handler.call(input, ctx, self)
  end

  def name
    "#{object_id}-<proc>"
  end

end