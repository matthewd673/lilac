# typed: strict
# frozen_string_literal: true

require "sorbet-runtime"
require_relative "analysis"
require_relative "cfg"
require_relative "dfa"
require_relative "cfg_facts"

include Analysis

module Analysis
  class ReachingDefs < DFA
    extend T::Sig
    extend T::Generic

    # Domain = definitions
    Domain = type_member { { fixed: String } }

    sig { params(cfg: CFG).void }
    def initialize(cfg)
      @all_defs = T.let(compute_all_defs(cfg), T::Set[Domain])

      super(Direction::Forwards,
            Set[], # boundary = empty set
            Set[], # init = empty set
            cfg)
    end

    sig { returns(CFGFacts[Domain]) }
    def run
      @cfg.each_block do |b|
        init_sets(b)
      end

      super
    end

    protected

    sig { params(block: BB).returns(T::Set[Domain]) }
    def meet(block)
      # union of OUT[P] for all predecessors P of B
      u = T.let(Set[], T::Set[Domain])

      @cfg.each_predecessor(block) do |p|
        u |= get_set(@out, p)
      end

      u
    end

    sig { params(block: BB).returns(T::Set[Domain]) }
    def transfer(block)
      # union of GEN[B] and (IN[B] - KILL[B])
      get_set(@gen, block) |
        (get_set(@in, block) - get_set(@kill, block))
    end

    private

    sig { params(b: BB).void }
    def init_sets(b)
      # initialize gen and kill sets
      @gen[b] = Set[]
      @kill[b] = Set[]

      # find all definitions in block
      b.stmt_list.each do |s|
        # only definitions are relevant
        unless s.is_a?(IL::Definition)
          next
        end

        key = s.id.key
        T.unsafe(@gen[b]).add(key)
      end

      # any def not in this block is killed here
      @kill[b] = @all_defs - T.unsafe(@gen[b])
    end

    sig { params(cfg: CFG).returns(T::Set[Domain]) }
    def compute_all_defs(cfg)
      all = Set[]

      cfg.each_block do |b|
        b.stmt_list.each do |s|
          # only definitions are relevant
          unless s.is_a?(IL::Definition)
            next
          end

          key = s.id.key
          T.unsafe(all).add(key)
        end
      end

      all
    end
  end
end
