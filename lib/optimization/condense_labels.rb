# typed: false
# TODO: supports typed: strict apart from one glitch, see TODO below
require "sorbet-runtime"
require_relative "../il"
require_relative "../debugger/pretty_printer"

class CondenseLabels < Optimization
  extend T::Sig

  sig { void }
  def initialize
    @id = T.let("condense_labels", String)
    @description = T.let("Condense adjacent labels", String)
    @level = T.let(0, Integer)
  end

  sig { params(program: IL::Program).void }
  def run(program)
    jump_map = {} # target name -> IL::Goto
    label_adj_map = {} # IL::Label -> the IL::Label immediately above it

    stmt_list = []
    program.each_stmt_with_index { |s, i|
      # identify adjacent labels
      last = stmt_list[-1]
      # TODO: sorbet is saying this code is unreachable? it gets reached though
      if s.is_a?(IL::Label) and last and last.is_a?(IL::Label)
        label_adj_map[s] = last
      # push all stmts to internal list except adjacent labels
      else
        stmt_list.push(s)
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

    # return a new program with the modified stmt_list
    new_program = IL::Program.new
    new_program.concat_stmt_list(stmt_list)
  end
end