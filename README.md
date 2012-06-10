flo
===

Simple interface for creating extensible multi-step proceedures using composition.  Flo attempts to provide a fluent interface for creative step-by-step processes or algorithms using composition rhather than inhertance.

#### The Problem
Often developers need to model a multi-step process that is reusable:  maybe the steps are the same but the execution of the steps very for different contexts, or maybe the step flow changes slightly in some cases but the logic of the steps is largely reused.  For this situation developers often implement a Template Method pattern.
A Template Method basically uses inheritence to share common logic, while varying the implementation of steps by overriding methods representing particular steps.  The GOF have said, however, that one should "favor composition over inheritence."  Some have gone further to say the "Inheritence is a code smell."
The essential problem with using inheritence with the Template Method is that the class tree can get pretty ugly if one needs to vary the implementation of steps AND the flow of steps.
What if, rather than using a template method, one could compose flows of steps, where the steps are pluggable members and the flow can by easily extended as well?

