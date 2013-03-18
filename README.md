Flo
===

# Note
*The following is presently an exercise in README Driven Design, though it is almost usable*

Flo is a simple library for composing extensible multi-step procedures.  Flo attempts to provide a fluent interface for creating step-by-step processes or algorithms using plugable steps, and an interface and conventions for interaction between the steps.  Flo is probably most applicable to batch jobs or background processing, but it is certainly not limited to that.

See the [introductory blog post](http://www.codecraftblog.com/2012/08/building-procedures-with-composition.html) for more background on the inspiration for Flo.

#### What Flo is
 - A fluent interface for building sequences (or directed graphs) of pluggable processing steps
 - A tool for creating complex Strategy patterns
 - A framework for batch processing

#### Compose-able Flows
The idea of Flo, is that one can easily define flows--directed graphs of pluggable steps with a fluent interface.  Some of the ideas from Spring Batch and Apache Camel have also inspired my thinking here, but Flo is much simpler and less specialized.  Both the flows and the step implementations should be readily testable.

Here's how you define a flow with by extending the Flo class and wiring together the steps in the constructor, or by creating a new Flo instance and using the fluent interface.  In either case, the code looks similar.  

```ruby
  # As an extension
  class ImportUsersFlo < Flo
    def initialize(step1, step2) 
      # name?
      start >> step1 >> -> (input, ctx) {step.status == 'OK' ? step2 : HandleErrorGeneric.new)
    end
  end
  ImportUsersFlo.new(RowMapperCSVFile.new(...), SaveARFromCsv.new(req_fields, ...)).start!
```

Note that, since the step implementations are "injected" in the constructor, different contexts (i.e. test) can easily plug in alternates.  Step implementations can have their own class hierarchy for shared processing behavior.


```ruby
  # As an Instance

  Flow.new >> step1 >> -> (step, ctx) {step.status == 'OK' ? step2 : HandleErrorGeneric.new)}.start!

```

#### Extending flows
Flo flows are not redily extensible in the OO sense, but by factoring the flows a developer can reuse flows in other flows.  The fluent interface provides for using a flow just like another flow step.