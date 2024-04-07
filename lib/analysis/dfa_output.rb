# typed: strict
require "sorbet-runtime"
require_relative "analysis"
require_relative "dfa"

# A DFAOutput stores the sets of facts (e.g.: GEN and KILL) that were
# computed by a data-flow analysis.
class Analysis::DFAOutput
  extend T::Sig
  extend T::Generic

  Domain = type_member

  sig { params(cfg: Analysis::CFG).void }
  # Construct a new DFAOutput.
  #
  # @param [CFG] cfg The CFG that the DFA was run on.
  def initialize(cfg)
    @facts = T.let(Hash.new,
                   T::Hash[Symbol, T::Hash[Analysis::BB, T::Set[Domain]]])
    @blocks = T.let(Set[], T::Set[Analysis::BB])

    # note all the blocks in the cfg
    cfg.each_node { |b|
      @blocks.add(b)
    }
  end

  sig { params(symbol: Symbol, set: T::Hash[Analysis::BB, T::Set[Domain]])
          .void }
  def add_fact_hash(symbol, set)
    @facts[symbol] = set
  end

  sig { params(symbol: Symbol, block: Analysis::BB).returns(T::Set[Domain]) }
  # Get a fact (set of objects in the analysis domain) for a basic block.
  #
  # @param [Symbol] symbol The symbol of the fact to retrieve.
  # @param [Analysis::BB] block The block whose fact to retrieve.
  # @return [T::Set[Domain]] A set of objects in the analysis domain. If the
  #   symbol does not exist in the DFAOutput or the block does not have any
  #   facts of this symbol associated with it then this will return empty set.
  def get_fact(symbol, block)
    fact_set = @facts[symbol]
    if not fact_set
      return Set[]
    end

    block_facts = fact_set[block]
    if not block_facts
      return Set[]
    end

    return block_facts
  end
end
