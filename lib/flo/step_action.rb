# Internal: Abstract class for step processors, factory
#
# A StepAction generally wraps an object that acts on flow data.  The contract for StepAction consists of the following
# - execute: perform whatever on the flow/step data
# - name: generate a unique name for the action
#

class StepAction
  attr_accessor :handler

  def initialize(proc)
    @handler = proc
  end

  def self.from_obj(proc)
    return FloStepAction.new(proc) if proc.respond_to?(:flo_step) # TODO check signature?
    return ProcStepAction.new(proc) if proc.kind_of? Proc
    raise ArgumentError.new "can't create a StepAction from #{proc.inspect}"
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

class FloStepAction < StepAction

  def execute(input, ctx)
    @handler.flo_step(input, ctx)
  end
end

class ProcStepAction < FloStepAction

  def execute(input, ctx)
    @handler.call(input, ctx)
  end

  def name
    "#{object_id}-<proc>"
  end

end