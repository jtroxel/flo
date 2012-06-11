flo
===

Simple interface for creating extensible multi-step proceedures using composition.  Flo attempts to provide a fluent interface for creative step-by-step processes or algorithms using composition rather than inhertance.

#### The Problem
Often developers need to model a multi-step process that is reusable:  maybe the steps are the same but the execution of the steps very for different contexts, or maybe the step flow changes slightly in some cases but the logic of the steps is largely reused.  For this situation developers often implement a Template Method pattern.

A Template Method basically uses inheritence to share common logic, while varying the implementation of steps by overriding methods representing particular steps.  The GOF have said, however, that one should "favor composition over inheritence."  Some have gone further to say the "Inheritence is a code smell."

The essential problem with using inheritence with the Template Method is that the class tree can get pretty ugly if one needs to vary the implementation of steps AND the flow of steps.

What if, rather than using a template method, one could compose flows of steps, where the steps are pluggable members and the flow can by easily extended as well?

#### Composable Flows
The idea of Flo, is that one can easily define flows--directed graphs of pluggable steps--kind of like a mix of the Template Method we've discussed and the Strategy pattern.  Some of the ideas from Spring Batch and Apache Camel have also colored my thinking here.  Both the flows and the step implementations should be redily testible.

Here's how you define a flow with by extending the Flo class and wiring together the steps in the constructor, or by creating a new Flo instance and using the fluent interface.  In either case, the code looks similar.  

```ruby
  # As an extension
  class ImportUsersFlo < Flo
    def initialize(step1, step2) 
      # name?
      start >> step1 >> -> (_.status == 'OK' ? step2 : HandleErrorGeneric.new)
    end
  end
  ImportUsersFlo.new(RowMapperCSVFile.new(...), SaveARFromCsv.new(req_fields, ...)).go
```
```ruby
  # As an Instance

  Flow.new >> step1 >> -> (_.status == 'OK' ? step2 : HandleErrorGeneric.new).go

```
Note that, since the step implementations are "injected" in the constructor, different contexts (i.e. test) can easily plug in alternates.  Step implementations have their own class hierarchy for shared processing bahavior.

#### Extending flows
How to extend a flow?  Just insert steps etc.
 - break into subflows
 - I/F for inserting, replacing steps?
