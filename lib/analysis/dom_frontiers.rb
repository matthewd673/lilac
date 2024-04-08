# typed: strict
require "sorbet-runtime"
require_relative "analysis"
require_relative "bb"
require_relative "cfg"
require_relative "dom_tree"
require_relative "dfa"
require_relative "cfg_facts"

class Analysis::DomFrontiers
  extend T::Sig

  include Analysis

  sig { params(cfg: CFG, dom_tree: DomTree).void }
  def initialize(cfg, dom_tree)
    @cfg = cfg
    @dom_tree = dom_tree

    @df = T.let(Hash.new, T::Hash[BB, T::Set[BB]])
    @cfg.each_node { |b|
      @df[b] = Set[]
    }
  end

  sig { returns(CFGFacts[BB]) }
  def run
    # DF algorithm
    # for each predecessor of each join node...
    @cfg.each_node { |j|
      # skip nodes that aren't join nodes
      if not @cfg.predecessors_length(j) > 1
        next
      end

      @cfg.each_predecessor(j) { |p|
        # walk up the dom tree from p until we find a node that dominates j
        runner = T.let(p, T.nilable(BB))

        # NOTE: original algorithm does not enforce runner != nil
        while runner and runner != @dom_tree.get_idom(j)
          @df[runner] = T.unsafe(@df[runner]) | [j] # add j to runner's DF
          runner = @dom_tree.get_idom(runner) # continue moving up dom tree
        end
      }
    }

    # build output
    facts = CFGFacts.new(@cfg)
    facts.add_fact_hash(:df, @df)
    return facts
  end
end
