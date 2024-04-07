# typed: strict
require "sorbet-runtime"
require_relative "optimization"
require_relative "optimization_pass"

include Optimization

class Optimization::PrecomputeCondJumps < OptimizationPass
  extend T::Sig
  extend T::Generic

  Unit = type_member { { fixed: T::Array[IL::Statement] } }

  sig { void }
  def initialize
    @id = T.let("precompute_cond_jumps", String)
    @description = T.let("Replace constant conditional jumps with unconditional jumps", String)
    @level = T.let(1, Integer)
    @unit_type = T.let(UnitType::StatementList, UnitType)
  end

  sig { params(unit: Unit).void }
  def run(unit)
    stmt_list = unit # alias

    replacement = []

    stmt_list.each_with_index { |s, i|
      # precompute jz
      if s.is_a?(IL::JumpZero) and s.cond.is_a?(IL::Constant)
        cond = T.cast(s.cond, IL::Constant)
        if cond.value == 0
          replacement.push({:index => i, :stmt => IL::Jump.new(s.target)})
        end
      # precompute jnz
      elsif s.is_a?(IL::JumpNotZero) and s.cond.is_a?(IL::Constant)
        cond = T.cast(s.cond, IL::Constant)
        if cond.value != 0
          replacement.push(:index => i, :stmt => IL::Jump.new(s.target))
        end
      end
    }

    replacement.each { |r|
      stmt_list[r[:index]] = r[:stmt]
    }
  end
end
