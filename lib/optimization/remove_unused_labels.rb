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

  sig { params(program: IL::Program).void }
  def run(program)
    stmt_list = []

    # find all labels that are jumped to
    jumped_labels = []
    program.item_list.each { |i|
      if not i.is_a?(IL::Jump) then next end

      if jumped_labels.include?(i.target) then next end
      jumped_labels.push(i.target)
    }

    # remove all labels that aren't jumped to
    program.item_list.each { |i|
      # only labels are relevant
      if not i.is_a?(IL::Label)
        stmt_list.push(i)
        next
      end

      # only include label if it is jumped to
      if jumped_labels.include?(i.name)
        stmt_list.push(i)
      end
    }

    # replace statement list on input program
    program.item_list.clear
    program.item_list.concat(stmt_list)
  end
end
