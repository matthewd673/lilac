# typed: strict
# frozen_string_literal: true

require "sorbet-runtime"
require_relative "analysis"
require_relative "bb"
require_relative "cfg"
require_relative "dom_tree"
require_relative "dfa"
require_relative "cfg_facts"

module Lilac
  module Analysis
    # Compute the dominance frontiers for a CFG.
    class DomFrontiers
      extend T::Sig

      include Analysis

      sig { params(cfg: CFG, dom_tree: DomTree).void }
      # Construct a new dominance frontiers analysis.
      #
      # @param [CFG] cfg The graph to perform the analysis on.
      # @param [DomTree] dom_tree The dominator tree for the CFG (which can be
      #   computed with a separate DFA).
      def initialize(cfg, dom_tree)
        @cfg = cfg
        @dom_tree = dom_tree

        @df = T.let({}, T::Hash[BB, T::Set[BB]])
        @cfg.each_node do |b|
          @df[b] = Set[]
        end
      end

      sig { returns(CFGFacts[BB]) }
      # Run the dominance frontiers analysis.
      #
      # @return [CFGFacts[BB]] A +CFGFacts+ object containing dominance frontier
      #   information for the graph. Dominance frontier information is stored
      #   in symbol +:df+.
      def run
        # DF algorithm
        # for each predecessor of each join node...
        @cfg.each_node do |j|
          # skip nodes that aren't join nodes
          if @cfg.predecessors_length(j) <= 1
            next
          end

          @cfg.each_predecessor(j) do |p|
            # walk up the dom tree from p until we find a node that dominates j
            runner = T.let(p, T.nilable(BB))

            # NOTE: original algorithm does not enforce runner != nil
            while runner && runner != @dom_tree.idom(j)
              @df[runner] = T.unsafe(@df[runner]) | [j] # add j to runner's DF
              runner = @dom_tree.idom(runner) # continue moving up dom tree
            end
          end
        end

        # build output
        facts = CFGFacts.new(@cfg)
        facts.add_fact_hash(:df, @df)
        facts
      end
    end
  end
end
