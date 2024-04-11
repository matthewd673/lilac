# typed: strict
require "sorbet-runtime"
require_relative "pass"
require_relative "il"
require_relative "graph"
require_relative "analysis/analysis"
require_relative "analysis/bb"
require_relative "analysis/cfg"
require_relative "analysis/live_vars"
require_relative "analysis/dominators"
require_relative "analysis/dom_tree"
require_relative "analysis/dom_frontiers"

class SSA < Pass
  extend T::Sig

  include Analysis

  sig { params(cfg: CFG).void }
  def initialize(cfg)
    @cfg = cfg

    # define some hashes and sets ahead of time for use later
    # NOTE: these constructions will be overwritten on run but thats ok for now
    @globals = T.let(Set[], T::Set[IL::ID])
    @blocks = T.let(Hash.new, T::Hash[IL::ID, T::Set[BB]])
    @df_facts = T.let(CFGFacts.new(cfg), CFGFacts[BB])

    @id = T.let("ssa", String)
    @description = T.let("Transform a CFG into SSA form", String)
  end

  sig { void }
  def run
    # find and split all critical edges
    critical_edges = find_critical_edges
    critical_edges.each { |e|
      split_edge(e)
    }

    # run dominators, dom tree, and dom frontiers analysis
    dominators = Dominators.new(@cfg)
    dom_cfg_facts = dominators.run

    dom_tree = DomTree.new(dom_cfg_facts)

    puts Debugger::GraphVisualizer::generate_graphviz(dom_tree)

    dom_frontiers = DomFrontiers.new(@cfg, dom_tree)
    @df_facts = dom_frontiers.run

    # find global names and add phi functions
    find_globals
    rewrite_with_phi_funcs

    # TODO: temporary debug printing
    @cfg.each_node { |b|
      puts("[#{b}]")
      b.each_stmt { |s|
        puts(s)
      }
      puts
    }

    # perform renaming
    puts "Renaming globals"
    rename_globals(dom_tree)

    # TODO: temporary debug printing
    @cfg.each_node { |b|
      puts("[#{b}]")
      b.each_stmt { |s|
        puts(s)
      }
      puts
    }
  end

  private

  sig { params(edge: Graph::Edge[BB]).void }
  def split_edge(edge)
    # delete old edge
    @cfg.delete_edge(edge)

    # create new block in the middle
    new_id = @cfg.max_block_id + 1
    new_block = BB.new(new_id, [])
    @cfg.add_block(new_block)

    # create new edges to and from the new block
    @cfg.create_edge(edge.from, new_block)
    @cfg.create_edge(new_block, edge.to)
  end

  sig { returns(T::Array[Graph::Edge[BB]]) }
  def find_critical_edges
    critical_edges = []

    @cfg.each_edge { |e|
      if @cfg.predecessors_length(e.to) > 1 and
         @cfg.successors_length(e.from) > 1
        critical_edges.push(e)
      end
    }

    return critical_edges
  end

  sig { void }
  def rewrite_with_phi_funcs
    # for each id in globals
    @globals.each { |id|
      work_list = @blocks[id]
      if not work_list
        work_list = Set[]
      end

      # for each block in work list
      work_list.each { |b|
        # for each block in DF(b)
        @df_facts.get_fact(:df, b).each { |d|
          # if d has no phi function for id...
          existing_phi = find_phi(d, id.name)
          if existing_phi # skip because it has a phi already
            next
          end

          # ...prepend phi for id in d and add d to work list
          phi = IL::Definition.new(IL::Type::I32, # TODO: correct types
                                   id,
                                   IL::Phi.new([])) # ids will be filled later

          d.unshift_stmt(phi) # TODO: don't insert phis before label

          work_list = work_list | [d]
        }
      }
    }
  end

  sig { params(block: BB, name: String).returns(T.nilable(IL::Phi)) }
  def find_phi(block, name)
    # scan block statements in order for matching phi
    block.each_stmt { |s|
      # blocks often start with a label, skip this
      if s.is_a?(IL::Label)
        next
      end

      # phi functions are Definitions with an rhs of type Phi
      # since phi functions must appear all at the beginning of the block,
      # as soon as we see a statement that doesn't match this we can stop
      # the check
      if (not s.is_a?(IL::Definition)) or (not s.rhs.is_a?(IL::Phi))
        break
      end

      # check if phi function applies to correct id
      if s.id.name == name
        return T.cast(s.rhs, IL::Phi)
      end
    }

    return nil
  end

  sig { void }
  def find_globals
    @globals.clear
    @blocks.clear

    # run live vars and union all of the upwardly exposed sets
    live_vars = LiveVars.new(@cfg)
    facts = live_vars.run

    @cfg.each_node { |b|
      facts.get_fact(:in, b).each { |id_name|
        # NOTE: live vars gives us Strings but we want IL::IDs
        # (these new IDs will all have number=0 which is find since the
        #  program isn't in SSA yet)
        id = IL::ID.new(id_name)

        # add every id to globals set
        @globals.add(id)

        # also note that this id was used within this block
        if not @blocks[id]
          @blocks[id] = Set[b]
        else
          T.unsafe(@blocks[id]).add(b)
        end
      }
    }
  end

  sig { params(dom_tree: DomTree).void }
  def rename_globals(dom_tree)
    counter = Hash.new
    stack = Hash.new

    # initialize set for each id
    @globals.each { |id|
      puts id.name
      counter[id.name] = 0
      stack[id.name] = []
    }

    # begin on root of dom tree (a.k.a. CFG entry)
    rename(@cfg.entry, counter, stack, dom_tree)
  end

  sig { params(name: String,
               counter: T::Hash[String, Integer],
               stack: T::Hash[String, T::Array[Integer]])
          .returns(IL::ID) }
  def new_name(name, counter, stack)
    # unsafes should never break
    # puts "read i for #{name}"
    i = T.unsafe(counter[name])
    if not i
      # TODO: fully resolve this and remove this whole condition
      puts("WARN: i for #{name} was nil")
      i = -1
      stack[name] = [] # will be needed later
    end
    counter[name] = i + 1
    T.unsafe(stack[name]).push(i)

    return IL::ID.new(name, number: i)
  end

  sig { params(block: BB,
               counter: T::Hash[String, Integer],
               stack: T::Hash[String, T::Array[Integer]],
               dom_tree: DomTree).void }
  def rename(block, counter, stack, dom_tree)
    # for each phi function in block, rewrite lhs with new_name
    block.each_stmt { |s|
      if s.is_a?(IL::Label)
        next
      end

      if (not s.is_a?(IL::Definition)) or (not s.rhs.is_a?(IL::Phi))
        break
      end

      # rewrite lhs with new_name
      s.id = new_name(s.id.name, counter, stack)
    }

    # for each definition in block
    block.each_stmt { |s|
      if not s.is_a?(IL::Definition)
        next
      end

      # rewrite rhs expression using stack
      rewrite_rhs(s.rhs, counter, stack)

      # rewrite lhs of definition with new_name
      s.id = new_name(s.id.name, counter, stack)
    }

    # for each successor of block in the *CFG*
    @cfg.each_successor(block) { |s|
      # fill in phi function arguments
      stack.keys.each { |name|
        # see if there is a phi for this name in the successor
        phi = find_phi(s, name)
        if not phi
          next
        end

        # if there is a phi for it, add the current subscript to the phi
        number = T.unsafe(stack[name])[-1]
        if not number # TODO: unsure how this can happen but it does
          next
        end

        phi.ids.push(IL::ID.new(name, number: number))
      }
    }

    # call rename on each successor of block in the *dom tree*
    dom_tree.each_successor(block) { |s|
      rename(s, counter, stack, dom_tree)
    }

    # for each definition (and each phi function, which are always definitions
    # in this IL), pop stack[lhs]
    block.each_stmt { |s|
      if not s.is_a?(IL::Definition)
        next
      end

      T.unsafe(stack[s.id.name]).pop()
    }
  end

  sig { params(rhs: T.any(IL::Expression, IL::Value),
               counter: T::Hash[String, Integer],
               stack: T::Hash[String, T::Array[Integer]]).void }
  def rewrite_rhs(rhs, counter, stack)
    case rhs
    # Constants have nothing to rewrite
    when IL::Constant then return
    # Phis will be handled somewhere else
    when IL::Phi then return
    when IL::ID
      # rewrite id with top of stack[name]
      puts "read #{rhs.name}"
      rhs.number = T.unsafe(T.unsafe(stack[rhs.name])[-1])
    when IL::BinaryOp
      # recurse on operands
      rewrite_rhs(rhs.left, counter, stack)
      rewrite_rhs(rhs.right, counter, stack)
    when IL::UnaryOp
      # recurse on operand
      rewrite_rhs(rhs.value, counter, stack)
    when IL::Call
      # recurse on all args
      rhs.args.each { |a|
        rewrite_rhs(a, counter, stack)
      }
    else
      raise("Attempted to rewrite unrecognized rhs: #{rhs.class}")
    end
  end
end
