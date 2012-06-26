require "flo/version"

module Flo
  class Flo

    attr_accessor :graph

    def initialize(options=nil)
      @graph = {}
      @flo = {} # member for flow-wide data
      @step = {} # data about the last step, re-assigned with results of each step
                 # TODO  where to put errors...  track input and output?
    end

    def >>(next_target)
      step_key = @graph.keys.size
      if next_target.respond_to? :flo_step # Add a step processor to graph
        if next_target.respond_to?(:name)
          step_key = "#{step_key}-#{next_target.name}"
        end
        @graph[step_key] = next_target
        self
      else
        if next_target.kind_of?(Proc)
          @graph["#{step_key}-<proc>"] = next_target
        end
      end
    end

    def start!(flo_init = nil)
      @flo = flo_init if flo_init
      walk_graph(@graph) do |step|
        @step = do_step(step, @step)
      end
    end

    def walk_graph(graph)
      graph.each do |key, node|
        if node.kind_of? Array
          node.each do |split_node|
            walk_graph(split_node)
          end
        end
        yield node
      end
    end

    ##
    # Perform a step in the flow.
    # - If the step is a "processor" (handles flo_step), then call flo_step
    # - If the step is a Proc that takes
    def do_step(node, step)
      if node.respond_to? :flo_step
        node.flo_step(step, @flo)
      else
        if node.kind_of? Proc
          node.call
        end
      end
    end
  end
end
