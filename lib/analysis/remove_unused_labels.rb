# typed: strict
require "sorbet-runtime"
require_relative "../il"

class RemoveUnusedLabels < Analysis
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
    program.each_stmt { |s|
      if not s.is_a?(IL::Jump) then next end

      if jumped_labels.include?(s.target) then next end
      jumped_labels.push(s.target)
    }

    # remove all labels that aren't jumped to
    program.each_stmt { |s|
      # only labels are relevant
      if not s.is_a?(IL::Label)
        stmt_list.push(s)
        next
      end

      # only include label if it is jumped to
      if jumped_labels.include?(s.name)
        stmt_list.push(s)
      end
    }

    # replace statement list on input program
    program.clear
    program.concat_stmt_list(stmt_list)
  end
end
