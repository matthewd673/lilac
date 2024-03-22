# typed: strict
require "sorbet-runtime"
require_relative "optimization"
require_relative "optimization_pass"

include Optimization

class Optimization::CondenseLabels < OptimizationPass
  extend T::Sig

  sig { void }
  def initialize
    @id = T.let("condense_labels", String)
    @description = T.let("Condense adjacent labels", String)
    @level = T.let(0, Integer)
  end

  sig { params(program: IL::Program).void }
  def run(program)
    # TODO: add function support
    jump_map = {} # target name -> IL::Goto
    label_adj_map = {} # IL::Label -> the IL::Label immediately above it

    stmt_list = []
    program.item_list.each { |i|
      # identify adjacent labels
      last = T.unsafe(stmt_list[-1]) # NOTE: workaround for sorbet 7006
      if i.is_a?(IL::Label) and last and last.is_a?(IL::Label)
        label_adj_map[i] = last
      # push all stmts to internal list except adjacent labels
      else
        stmt_list.push(i)
      end

      # mark jumps
      if i.is_a?(IL::Jump)
        if jump_map.include?(i.target)
          jump_map[i.target].push(i)
        else
          jump_map[i.target] = [i]
        end
      end
    }

    label_adj_map.keys.reverse_each { |c|
      # redirect all jumps pointing at the adj label to its predecessor
      jump_map[c.name].each { |j|
        j.target = label_adj_map[c].name

        # copy jumps in map to reflect their new target
        # we don't have to remove them from their old location since that label
        # will never be read again (and we're iterating through that collection
        # right now so removing it would be awkward)
        if jump_map.include?(j.target)
          jump_map[j.target].push(j)
        else
          jump_map[j.target] = [j]
        end
      }
    }

    # replace statement list on input program
    program.item_list.clear
    program.item_list.concat(stmt_list)
  end
end
