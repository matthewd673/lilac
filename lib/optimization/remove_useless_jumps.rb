# typed: strict
require "sorbet-runtime"
require_relative "optimization"
require_relative "optimization_pass"

include Optimization

class Optimization::RemoveUselessJumps < OptimizationPass
  extend T::Sig

  sig { void }
  def initialize
    @id = T.let("remove_useless_jumps", String)
    @description = T.let("Remove jumps to the very next line", String)
    @level = T.let(0, Integer)
  end

  sig { params(program: IL::Program).void }
  def run(program)
    stmt_list = []
    program.item_list.each { |i|
      # identify labels directly below a jump that points to them
      last = T.unsafe(stmt_list[-1]) # NOTE: workaround for sorbet 7006
      if i.is_a?(IL::Label) and last and last.is_a?(IL::Jump) and
         last.target.eql?(i.name) and not last.class.method_defined?(:cond)
        stmt_list.pop
      end

      stmt_list.push(i)
    }

    # replace statement list on input program
    program.item_list.clear
    program.item_list.concat(stmt_list)
  end
end
