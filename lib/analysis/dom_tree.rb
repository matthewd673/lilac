# typed: strict
require "sorbet-runtime"
require_relative "../graph"
require_relative "analysis"
require_relative "bb"
require_relative "cfg_facts"

class Analysis::DomTree < Graph
  extend T::Sig
  extend T::Generic

  include Analysis

  Node = type_member { { fixed: BB } }

  sig { params(dom_cfg_facts: CFGFacts[BB]).void }
  def initialize(dom_cfg_facts)
    super()

    compute_graph(dom_cfg_facts)
  end

  sig { params(block: BB).returns(T.nilable(BB)) }
  # Get the IDOM for a block in the tree by traversing the tree.
  #
  # @param [BB] block Find IDOM of this block.
  # @return [T.nilable(BB)] The IDOM of the block. In a valid dominator tree
  #   this will only be nil for the ENTRY block in the CFG.
  def get_idom(block)
    preds = @predecessors[block]
    if not preds
      nil
    else
      # there is only one IDOM in a valid graph
      preds.to_a[0]
    end
  end

  sig { params(block: BB).returns(T::Set[BB]) }
  # Get the SDOM set for a block in the tree by recursively traversing the
  # tree.
  #
  # @param [BB] block Find SDOM of this block.
  # @return [T::Set[BB]] The SDOM set of the block. In a valid dominator tree
  #   this set will only be empty for the ENTRY block in the CFG.
  def get_sdom(block)
    sdom = T.let(Set[], T::Set[BB])
    preds = @predecessors[block]
    if not preds
      return Set[]
    end

    preds.each { |p|
      sdom = sdom | get_sdom(p)
    }

    return sdom
  end

  private

  sig { params(cfg_facts: CFGFacts[BB]).void }
  def compute_graph(cfg_facts)
    cfg_facts.cfg.each_node { |b|
      @nodes.push(b)

      # find idom and create an edge from it to this block
      idom = compute_idom(cfg_facts, b)

      if not idom # should only be true for ENTRY
        next
      end

      create_edge(idom, b)
    }
  end

  sig { params(cfg_facts: CFGFacts[BB], block: BB)
          .returns(T.nilable(BB)) }
  def compute_idom(cfg_facts, block)
    idom = T.let(nil, T.nilable(BB))
    idom_dist = -1

    cfg_facts.get_fact(:out, block).each { |d|
      dom_dist = find_dom_dist(cfg_facts.cfg, block, d, 0)
      if dom_dist > 0 and
         (idom_dist == -1 or dom_dist < idom_dist)
        idom = d
      end
    }

    return idom
  end

  sig { params(cfg: CFG, block: BB, dom: BB, dist: Integer)
          .returns(Integer) }
  def find_dom_dist(cfg, block, dom, dist)
    # check if self is dom
    if block == dom
      return dist
    end

    # recursively check all predecessors
    cfg.each_predecessor(block) { |p|
      dist = find_dom_dist(cfg, p, dom, dist + 1)
      if dist >= 0
        return dist
      end
    }

    return -1 # not found
  end
end
