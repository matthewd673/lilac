# typed: strict
require "sorbet-runtime"
require_relative "optimization"
require_relative "optimization_pass"

include Optimization

class Optimization::PrecomputeCondJumps < OptimizationPass
  extend T::Sig

  sig { void }
  def initialize
    @id = T.let("precompute_cond_jumps", String)
    @description = T.let("Replace constant conditional jumps with unconditional jumps", String)
    @level = T.let(1, Integer)
  end

  sig { params(program: IL::Program).void }
  def run(program)
    stmt_list = []
    program.item_list.each { |i|
      # precompute jz
      if i.is_a?(IL::JumpZero) and i.cond.is_a?(IL::Constant)
        cond = T.cast(i.cond, IL::Constant)
        if cond.value == 0
          stmt_list.push(IL::Jump.new(i.target))
        end
      # precompute jnz
      elsif i.is_a?(IL::JumpNotZero) and i.cond.is_a?(IL::Constant)
        cond = T.cast(i.cond, IL::Constant)
        if cond.value != 0
          stmt_list.push(IL::Jump.new(i.target))
        end
      # if statement is not a jump that we're modifying, just push it to list
      else
        stmt_list.push(i)
      end
    }

    # replace statement list on input program
    program.item_list.clear
    program.item_list.concat(stmt_list)
  end
end
