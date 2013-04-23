module Flo::Processor
  class HashPrinter
    def execute(input, ctx=nil)
      print_row(input, 1)
      input
    end
    def print_row(row, level=1)
      row.each do |k, v|
        level_s = level ? (0..level-1).map{'-'}.join('') : ''
        if v.respond_to?(:keys)
          puts "#{level_s}#{k}"
          print_row(v, level+1) if v
        else
          puts "#{level_s}#{k}\t#{v}"
        end
      end
    end
  end
end