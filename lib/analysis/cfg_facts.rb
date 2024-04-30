# typed: strict
# frozen_string_literal: true
require "sorbet-runtime"
require_relative "analysis"

# A CFGFacts object stores the sets of facts (e.g.: GEN and KILL) that were
# computed by an analysis about a CFG.
module Analysis
  class CFGFacts
  extend T::Sig
  extend T::Generic

  include Analysis

  Domain = type_member {{ upper: Object }}

  sig { returns(CFG) }
  attr_reader :cfg

  sig { params(cfg: CFG).void }
  # Construct a new CFGFacts object.
  #
  # @param [CFG] cfg The CFG that the analysis was run on.
  def initialize(cfg)
    @facts = T.let({}, T::Hash[Symbol, T::Hash[BB, T::Set[Domain]]])
    @cfg = cfg
  end

  sig { params(symbol: Symbol, hash: T::Hash[BB, T::Set[Domain]]).void }
  # Add a hash of facts (with a mapping of +BB+ => +Set[Domain]+) to the
  # fact set for a given symbol. For example, the OUT set of all blocks may
  # be added as a fact hash with symbol +:out+ and a hash of all blocks
  # mapped to the domain objects in their OUT set.
  #
  # @param [Symbol] symbol The symbol of the fact hash.
  # @param [T::Hash[BB, T::Set[Domain]]] hash The hash of blocks mapped to
  #   sets of facts.
  def add_fact_hash(symbol, hash)
    @facts[symbol] = hash
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
    unless fact_set
      return Set[]
    end

    block_facts = fact_set[block]
    unless block_facts
      return Set[]
    end

    block_facts
  end

  sig { returns(String) }
  def to_s
    str = ""
    @cfg.each_node do |b|
      str += "#{b.id} => {\n"
      @facts.each_key do |k|
        str += "  #{k} => {"
        get_fact(k, b).each do |o|
          str += "#{o.to_s}, "
        end
        str.chomp!(", ")
        str += "},\n"
      end
      str += "},\n"
    end
    str.chomp!("\n")
    str
  end
  end
end
