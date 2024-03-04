# typed: false
# TODO: same erroneous sorbet 7006 error as condense_labels.rb
require "sorbet-runtime"
require_relative "analysis"

include Analysis

class Analysis::RemoveUselessJumps < AnalysisPass
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
    program.each_stmt { |s|
      # identify labels directly below a jump that points to them
      last = stmt_list[-1]
      if s.is_a?(IL::Label) and last and last.is_a?(IL::Jump) and
         last.target.eql?(s.name) and not last.class.method_defined?(:cond)
        stmt_list.pop
      end

      stmt_list.push(s)
    }

    # replace statement list on input program
    program.clear
    program.concat_stmt_list(stmt_list)
  end
end
