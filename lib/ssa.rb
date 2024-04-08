# typed: strict
require "sorbet-runtime"
require_relative "pass"
require_relative "il"
require_relative "graph"
require_relative "analysis"
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

    dom_frontiers = DomFrontiers.new(@cfg, dom_tree)
    @df_facts = dom_frontiers.run

    # find global names and add phi functions
    find_globals
    rewrite_with_phi_funcs

    # TODO: incomplete
    raise("Implementation is incomplete")
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
          if has_phi?(d, id)
            next
          end

          # ...prepend phi for id in d and add d to work list
          phi = IL::Definition.new(IL::Type::I32, # TODO: correct types
                                   id,
                                   IL::Phi.new([])) # TODO: correct phi args
          d.unshift_stmt(phi)
          work_list = work_list | [d]
        }
      }
    }
  end

  sig { params(block: BB, id: IL::ID).returns(T::Boolean) }
  def has_phi?(block, id)
    # scan block statements in order for matching phi
    block.each_stmt { |s|
      # phi functions are Definitions with an rhs of type Phi
      # since phi functions must appear all at the beginning of the block,
      # as soon as we see a statement that doesn't match this we can stop
      # the check
      if not s.is_a?(IL::Definition)
        break
      end

      if not s.rhs.is_a?(IL::Phi)
        break
      end

      # check if phi function applies to correct id
      if s.id.eql?(id)
        return true
      end
    }

    return false
  end

  sig { void }
  def find_globals
    @globals.clear

    # run live vars and union all of the upwardly exposed sets
    live_vars = LiveVars.new(@cfg)
    facts = live_vars.run

    @cfg.each_node { |b|
      facts.get_fact(:out, b).each { |id|
        # NOTE: live vars gives us Strings but we want IL::IDs
        # (these new IDs will all have number=0 which is find since the
        #  program isn't in SSA yet)
        @globals.add(IL::ID.new(id))
      }
    }
  end
end
