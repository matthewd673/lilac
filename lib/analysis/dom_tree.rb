# typed: strict
require "sorbet-runtime"
require_relative "../graph"
require_relative "analysis"
require_relative "bb"
require_relative "dfa_output"

class Analysis::DomTree < Graph
  extend T::Sig
  extend T::Generic

  include Analysis

  Node = type_member { { fixed: BB } }

  sig { params(dfa_output: Analysis::DFAOutput[BB]).void }
  def initialize(dfa_output)
    super()

    compute_graph(dfa_output)
  end

  private

  sig { params(dfa_output: Analysis::DFAOutput[BB]).void }
  def compute_graph(dfa_output)
    dfa_output.cfg.each_node { |b|
      @nodes.push(b)

      # find idom and create an edge from it to this block
      idom = find_idom(dfa_output, b)

      if not idom # should only be true for ENTRY
        next
      end

      create_edge(idom, b)
    }
  end

  sig { params(dfa_output: DFAOutput[BB], block: BB).returns(T.nilable(BB)) }
  def find_idom(dfa_output, block)
    idom = T.let(nil, T.nilable(BB))
    idom_dist = -1

    dfa_output.get_fact(:out, block).each { |d|
      dom_dist = find_dom_dist(dfa_output.cfg, block, d, 0)
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
    cfg.each_predecessor(block) { |b|
      dist = find_dom_dist(cfg, block, dom, dist + 1)
      if dist >= 0
        return dist
      end
    }

    return -1 # not found
  end
end
