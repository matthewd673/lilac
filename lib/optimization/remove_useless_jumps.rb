# typed: strict
require "sorbet-runtime"
require_relative "optimization"
require_relative "optimization_pass"

include Optimization

class Optimization::RemoveUselessJumps < OptimizationPass
  extend T::Sig
  extend T::Generic

  Unit = type_member { { fixed: T::Array[IL::Statement] } }

  sig { override.returns(String) }
  def id
    "remove_useless_jumps"
  end

  sig { override.returns(String) }
  def description
    "Remove jumps to the very next statement"
  end

  sig { override.returns(Integer) }
  def level
    0
  end

  sig { override.returns(UnitType) }
  def unit_type
    UnitType::StatementList
  end

  sig { params(unit: Unit).void }
  def run(unit)
    stmt_list = unit # alias

    deletion = []

    stmt_list.each { |s|
      # identify labels directly below a jump that points to them
      last = T.unsafe(stmt_list[-1]) # NOTE: workaround for sorbet 7006
      if s.is_a?(IL::Label) and last and last.is_a?(IL::Jump) and
         last.target.eql?(s.name) and not last.class.method_defined?(:cond)
        deletion.push(last)
      end
    }

    deletion.each { |d|
      stmt_list.delete(d)
    }
  end
end
