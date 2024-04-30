# typed: strict
# frozen_string_literal: true

require "sorbet-runtime"
require_relative "analysis"
require_relative "bb"
require_relative "cfg"
require_relative "dfa"
require_relative "cfg_facts"

# The Dominators analysis is a DFA that computes the set of dominators for
# each basic block in the CFG. The output of this can be used to compute
# a dominator tree (and, therefore, perform dominance frontiers analysis).
module Analysis
  class Dominators < Analysis::DFA
    extend T::Sig
    extend T::Generic

    # Domain = basic blocks
    Domain = type_member { { fixed: BB } }

    sig { params(cfg: CFG).void }
    # Construct a new Dominators analysis.
    #
    # @param [CFG] cfg The CFG that the analysis will run on.
    def initialize(cfg)
      # gather all blocks
      @all_blocks = T.let(Set[], T::Set[Domain])
      cfg.each_node do |b|
        @all_blocks.add(b)
      end

      super(Direction::Forwards,
            Set[cfg.entry], # boundary
            @all_blocks, # init
            cfg)
    end

    sig { returns(CFGFacts[Domain]) }
    # Run the Dominators analysis.
    #
    # @return [CFGFacts[Domain]] A +CFGFacts+ containing information about
    #   each block's dominators (which are stored in +:out+).
    def run
      @cfg.each_node do |b|
        init_sets(b)
      end

      super
    end

    protected

    sig { params(block: BB).returns(T::Set[Domain]) }
    def meet(block)
      # intersection of OUT[P] for all predecessors P of B
      i = @all_blocks
      preds = 0

      @cfg.each_predecessor(block) do |p|
        preds += 1
        i &= get_set(@out, p)
      end

      # no predecessors = empty set
      if preds == 0
        i = Set[]
      end

      i
    end

    sig { params(block: BB).returns(T::Set[Domain]) }
    def transfer(block)
      # union of IN[B] and GEN[B]
      get_set(@in, block) | get_set(@gen, block)
    end

    private

    sig { params(block: BB).void }
    def init_sets(block)
      # initialize gen and kill sets
      @gen[block] = Set[block]
      @kill[block] = Set[]
    end
  end
end
