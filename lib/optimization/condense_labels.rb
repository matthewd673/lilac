# typed: strict
require "sorbet-runtime"
require_relative "optimization"
require_relative "optimization_pass"

include Optimization

class Optimization::CondenseLabels < OptimizationPass
  extend T::Sig
  extend T::Generic

  Unit = type_member { { fixed: T::Array[IL::Statement] } }

  sig { void }
  def initialize
    @id = T.let("condense_labels", String)
    @description = T.let("Condense adjacent labels", String)
    @level = T.let(0, Integer)
    @unit_type = T.let(UnitType::StatementList, UnitType)
  end

  sig { params(unit: Unit).void }
  def run(unit)
    stmt_list = unit # alias

    jump_map = {} # target name -> IL::Goto
    label_adj_map = {} # IL::Label -> the IL::Label immediately above it

    deletion = []

    stmt_list.each_with_index { |s, i|
      # identify adjacent labels
      last = T.unsafe(stmt_list[i - 1]) # NOTE: workaround for sorbet 7006
      if s.is_a?(IL::Label) and last and last.is_a?(IL::Label)
        label_adj_map[s] = last
        deletion.push(s) # remove adjacent labels
      end

      # mark jumps
      if s.is_a?(IL::Jump)
        if jump_map.include?(s.target)
          jump_map[s.target].push(s)
        else
          jump_map[s.target] = [s]
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

    # delete all marked stmts
    deletion.each { |s|
      stmt_list.delete(s)
    }
  end
end
