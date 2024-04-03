# typed: strict
require "sorbet-runtime"
require_relative "optimization"
require_relative "optimization_pass"

include Optimization

class Optimization::RemoveUnusedLabels < OptimizationPass
  extend T::Sig

  sig { void }
  def initialize
    @id = T.let("remove_unused_labels", String)
    @description = T.let("Remove labels that are never targeted", String)
    @level = T.let(0, Integer)
  end

  sig { params(stmt_list: T::Array[IL::Statement]).void }
  def run(stmt_list)
    stmt_list = []

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
        stmt_list.push(s)
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
