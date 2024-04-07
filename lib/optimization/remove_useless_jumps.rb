# typed: strict
require "sorbet-runtime"
require_relative "optimization"
require_relative "optimization_pass"

include Optimization

class Optimization::RemoveUselessJumps < OptimizationPass
  extend T::Sig
  extend T::Generic

  Unit = type_member { { fixed: T::Array[IL::Statement] } }

  sig { void }
  def initialize
    @id = T.let("remove_useless_jumps", String)
    @description = T.let("Remove jumps to the very next line", String)
    @level = T.let(0, Integer)
    @unit_type = T.let(UnitType::StatementList, UnitType)
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
