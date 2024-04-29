# typed: strict
require "sorbet-runtime"
require_relative "optimization"
require_relative "optimization_pass"
require_relative "../il"

include Optimization

class Optimization::RemoveUnusedLabels < OptimizationPass
  extend T::Sig
  extend T::Generic

  Unit = type_member { { fixed: T::Array[IL::Statement] } }

  sig { override.returns(String) }
  def id
    "remove_unused_labels"
  end

  sig { override.returns(String) }
  def description
    "Remove labels that are never targeted"
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

    # find all labels that are jumped to
    jumped_labels = []
    stmt_list.each { |s|
      if not s.is_a?(IL::Jump) then next end

      if jumped_labels.include?(s.target) then next end
      jumped_labels.push(s.target)
    }

    # delete all labels that aren't jumped to
    deletion = []
    stmt_list.each { |s|
      # only labels are relevant
      if not s.is_a?(IL::Label)
        next
      end

      # only delete label if it is not jumped to
      if not jumped_labels.include?(s.name)
        deletion.push(s)
      end
    }

    deletion.each { |d|
      stmt_list.delete(d)
    }
  end
end
