# typed: strict
# frozen_string_literal: true
require "sorbet-runtime"
require_relative "../graph"
require_relative "analysis"
require_relative "bb"
require_relative "cfg_facts"

module Analysis
  class DomTree < Graph
  extend T::Sig
  extend T::Generic

  include Analysis

  Node = type_member { { fixed: BB } }

  sig { returns(BB) }
  attr_reader :entry

  sig { params(dom_cfg_facts: CFGFacts[BB]).void }
  # Construct a new dominator tree from the +CFGFacts+ produced by a
  # dominators analysis.
  #
  # @param [CFGFacts[BB]] dom_cfg_facts The output of a dominators analysis
  #   (such as that produced by +Analysis::Dominators+) which will be used
  #   to compute the dominator tree.
  def initialize(dom_cfg_facts)
    super()

    compute_graph(dom_cfg_facts)

    @entry = T.let(dom_cfg_facts.cfg.entry, BB)
  end

  sig { params(node: BB).returns(T.nilable(BB)) }
  # Find the node that immediately dominates the given node.
  #
  # @param [BB] node Find IDOM of this block.
  # @return [T.nilable(BB)] The IDOM of the block. In a valid dominator tree
  #   this will only be nil for the ENTRY block in the CFG.
  def idom(node)
    incoming = @incoming[node]
    if !incoming
      nil
    else
      # there is only one IDOM in a valid graph
      idom_edge = incoming.to_a[0]
      unless idom_edge
        return nil
      end

      idom_edge.from
    end
  end

  sig { params(node: BB, block: T.proc.params(arg0: BB).void).void }
  # Iterate over the nodes that strictly dominate the given node.
  #
  # @param [BB] node Find SDOM of this block.
  def sdom(node, &block)
    # yield each predecessor and recurse on them
    each_incoming(node) do |i|
      yield i.from
      sdom(node, &block)
    end
  end

  sig { params(node: BB, block: T.proc.params(arg0: BB).void).void }
  # Iterate over the nodes that are dominated by this node.
  #
  # @param [BB] node The node to search from.
  def dom_by(node, &block)
    yield node
    each_outgoing(node) do |o|
      dom_by(o.to, &block)
    end
  end

  private

  sig { params(cfg_facts: CFGFacts[BB]).void }
  def compute_graph(cfg_facts)
    cfg_facts.cfg.each_node do |b|
      add_node(b)

      # find idom and create an edge from it to this block
      idom = compute_idom(cfg_facts, b)

      unless idom # should only be true for ENTRY
        next
      end

      add_edge(Edge.new(idom, b))
    end
  end

  sig do params(cfg_facts: CFGFacts[BB], block: BB)
          .returns(T.nilable(BB)) end
  def compute_idom(cfg_facts, block)
    idom = T.let(nil, T.nilable(BB))
    idom_dist = -1

    cfg_facts.get_fact(:out, block).each do |d|
      dom_dist = find_dom_dist(cfg_facts.cfg, block, d, 0)
      if dom_dist > 0 and
         (idom_dist == -1 or dom_dist < idom_dist)
        idom = d
      end
    end

    idom
  end

  sig do params(cfg: CFG, block: BB, dom: BB, dist: Integer)
          .returns(Integer) end
  def find_dom_dist(cfg, block, dom, dist)
    # check if self is dom
    if block == dom
      return dist
    end

    # recursively check all predecessors
    cfg.each_predecessor(block) do |p|
      dist = find_dom_dist(cfg, p, dom, dist + 1)
      if dist >= 0
        return dist
      end
    end

    -1 # not found
  end
  end
end
