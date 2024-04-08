# typed: strict
require "sorbet-runtime"
require_relative "analysis"

# An AnalysisOutput stores the sets of facts (e.g.: GEN and KILL) that were
# computed by an analysis.
class Analysis::CFGFacts
  extend T::Sig
  extend T::Generic

  include Analysis

  Domain = type_member

  sig { returns(CFG) }
  attr_reader :cfg

  sig { params(cfg: CFG).void }
  # Construct a new CFGFacts object.
  #
  # @param [CFG] cfg The CFG that the analysis was run on.
  def initialize(cfg)
    @facts = T.let(Hash.new, T::Hash[Symbol, T::Hash[BB, T::Set[Domain]]])
    @cfg = cfg
  end

  sig { params(symbol: Symbol, set: T::Hash[BB, T::Set[Domain]]).void }
  def add_fact_hash(symbol, set)
    @facts[symbol] = set
  end

  sig { params(symbol: Symbol, block: BB).returns(T::Set[Domain]) }
  # Get a fact (set of objects in the analysis domain) for a basic block.
  #
  # @param [Symbol] symbol The symbol of the fact to retrieve.
  # @param [Analysis::BB] block The block whose fact to retrieve.
  # @return [T::Set[Domain]] A set of objects in the analysis domain. If the
  #   symbol does not exist in the CFGFacts or the block does not have
  #   any facts of this symbol associated with it then this will return
  #   empty set.
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