# typed: strict
require "sorbet-runtime"
require_relative "analysis"
require_relative "bb"
require_relative "cfg"
require_relative "dfa"

class Analysis::Dominators < Analysis::DFA
  extend T::Sig
  extend T::Generic

  # Domain = basic blocks
  Domain = type_member {{ lower: BB }}

  sig { params(cfg: CFG).void }
  def initialize(cfg)
    # gather all blocks
    @all_blocks = T.let(Set[], T::Set[Domain])
    cfg.each_block { |b|
      @all_blocks.add(b)
    }

    super(Direction::Forwards,
          Set[cfg.entry], # boundary
          @all_blocks, # init
          cfg)
  end

  sig { returns(T::Hash[Integer, T::Set[Integer]]) }
  def run
    return {} # TODO
  end

  protected

  sig { params(block: BB).returns(T::Set[Domain]) }
  def meet(block)
    # intersection of OUT[P] for all predecessors P of B

    i = @all_blocks
    preds = 0

    @cfg.each_predecessor(block) { |p|
      preds += 1

      out_p = @out[p.id]
      if not out_p
        out_p = Set[]
      end

      i = i & out_p
    }

    # no predecessors = empty set
    if preds == 0
      i = Set[]
    end

    return i
  end

  sig { params(block: BB).returns(T::Set[Domain]) }
  def transfer(block)
    # union of IN[B] and GEN[B]

    in_b = @in[block.id]
    if not in_b
      in_b = Set[]
    end

    gen_b = @gen[block.id]
    if not gen_b
      gen_b = Set[]
    end

    return in_b | gen_b
  end
end
