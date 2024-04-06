# typed: strict
require "sorbet-runtime"
require_relative "analysis"
require_relative "cfg"
require_relative "dfa"

include Analysis

class Analysis::ReachingDefs < DFA
  extend T::Sig
  extend T::Generic

  # Domain = definitions
  Domain = type_member {{ lower: String }}

  sig { params(cfg: CFG).void }
  def initialize(cfg)
    @all_defs = T.let(compute_all_defs(cfg), T::Set[Domain])

    super(Direction::Forwards,
          Set[], # boundary = empty set
          Set[], # init = empty set
          cfg)
  end

  sig { params(cfg: CFG).void }
  def run(cfg)
    cfg.each_block { |b|
      init_sets(b)
    }

    run_dfa(cfg)
  end

  protected

  sig { params(block: BB).returns(T::Set[Domain]) }
  def meet(block)
    # union of OUT[P] for all predecessors P of B
    u = T.let(Set[], T::Set[Domain])

    @cfg.each_predecessor(block) { |p|
      u = u | get_set(@out, p)
    }

    return u
  end

  sig { params(block: BB).returns(T::Set[Domain]) }
  def transfer(block)
    # union of GEN[B] and (IN[B] - KILL[B])
    return get_set(@gen, block) |
      (get_set(@in, block) - get_set(@kill, block))
  end

  private

  sig { params(b: BB).void }
  def init_sets(b)
    # initialize gen and kill sets
    @gen[b.id] = Set[]
    @kill[b.id] = Set[]

    # find all definitions in block
    b.each_stmt { |s|
      # only definitions are relevant
      if not s.is_a?(IL::Definition)
        next
      end

      key = s.id.key
      T.unsafe(@gen[b.id]).add(key)
    }

    # any def not in this block is killed here
    @kill[b.id] = @all_defs - T.unsafe(@gen[b.id])
  end

  sig { params(cfg: CFG).returns(T::Set[Domain]) }
  def compute_all_defs(cfg)
    all = Set[]

    cfg.each_block { |b|
      b.each_stmt { |s|
        # only definitions are relevant
        if not s.is_a?(IL::Definition)
          next
        end

        key = s.id.key
        T.unsafe(all).add(key)
      }
    }

    return all
  end
end
