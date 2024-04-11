# typed: strict
require "sorbet-runtime"
require_relative "analysis"
require_relative "cfg"
require_relative "cfg_facts"

# A DFA is a generic framework for a data-flow analysis.
class Analysis::DFA
  extend T::Sig
  extend T::Generic

  include Analysis

  Domain = type_member {{ upper: Object }}

  # The Direction enum specifies if a DFA runs forwards or backwards.
  class Direction < T::Enum
    enums do
      Forwards = new
      Backwards = new
    end
  end

  sig { params(direction: Direction,
               boundary: T::Set[Domain],
               init: T::Set[Domain],
               cfg: CFG).void }
  def initialize(direction, boundary, init, cfg)
    @direction = direction
    @boundary = boundary
    @init = init
    @cfg = cfg

    @out = T.let(Hash.new, T::Hash[BB, T::Set[Domain]])
    @in = T.let(Hash.new, T::Hash[BB, T::Set[Domain]])
    @gen = T.let(Hash.new, T::Hash[BB, T::Set[Domain]])
    @kill = T.let(Hash.new, T::Hash[BB, T::Set[Domain]])
  end

  sig { returns(CFGFacts[Domain]) }
  def run
    # run the dfa
    run_dfa

    # construct and return a CFGFacts object
    facts = CFGFacts.new(@cfg)
    facts.add_fact_hash(:out, @out)
    facts.add_fact_hash(:in, @in)
    facts.add_fact_hash(:gen, @gen)
    facts.add_fact_hash(:kill, @kill)

    return facts
  end

  protected

  sig { void }
  def run_dfa
    case @direction
    when Direction::Forwards then run_forwards
    when Direction::Backwards then run_backwards
    else T.absurd(@direction)
    end
  end

  sig { params(block: BB).returns(T::Set[Domain]) }
  def transfer(block)
    raise("Transfer function is unimplemented")
  end

  sig { params(block: BB).returns(T::Set[Domain]) }
  def meet(block)
    raise("Meet function is unimplemented")
  end

  sig { params(hash: T::Hash[BB, T::Set[Domain]], block: BB)
          .returns(T::Set[Domain]) }
  def get_set(hash, block)
    set_b = hash[block]

    if not set_b
      set_b = Set[]
    end

    return set_b
  end

  private

  sig { void }
  def run_forwards
    # initialize all nodes
    @out[@cfg.entry] = @boundary
    @cfg.each_block { |b|
      if b == @cfg.entry then next end

      @out[b] = @init
    }

    # iterate
    changed = T.let(true, T::Boolean)
    while changed
      changed = false
      @cfg.each_block { |b|
        if b == @cfg.entry then next end

        old_out = T.unsafe(@out[b])

        step_forwards(b)

        new_out = T.unsafe(@out[b])
        if old_out.length != new_out.length
          changed = true
        end
      }
    end
  end

  sig { params(block: BB).void }
  def step_forwards(block)
    @out[block] = transfer(block)
    @in[block] = meet(block)
  end

  sig { void }
  def run_backwards
    # initialize all nodes
    @in[@cfg.exit] = @boundary
    @cfg.each_block { |b|
      if b == @cfg.exit then next end

      @in[b] = @init
    }

    # iterate
    changed = T.let(true, T::Boolean)
    while changed
      changed = false
      @cfg.each_block { |b|
        if b == @cfg.exit then next end

        old_in = T.unsafe(@in[b])

        step_backwards(b)

        new_in = T.unsafe(@in[b])
        if old_in.length != new_in.length
          changed = true
        end
      }
    end
  end

  sig { params(block: BB).void }
  def step_backwards(block)
    @in[block] = transfer(block)
    @out[block] = meet(block)
  end
end
