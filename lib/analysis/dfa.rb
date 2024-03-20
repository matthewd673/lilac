# typed: strict
require "sorbet-runtime"
require "set"
require_relative "analysis"
require_relative "cfg"

class Analysis::DFA < AnalysisPass
  extend T::Sig
  extend T::Generic

  include Analysis

  Domain = type_member

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
    @id = T.let("dfa", String)
    @description = T.let("Generic data flow analysis", String)
    @level = T.let(-1, Integer)

    @direction = direction
    @boundary = boundary
    @init = init
    @cfg = cfg

    @out = T.let(Hash.new, T::Hash[Integer, T::Set[Domain]])
    @in = T.let(Hash.new, T::Hash[Integer, T::Set[Domain]])
    @gen = T.let(Hash.new, T::Hash[Integer, T::Set[Domain]])
    @kill = T.let(Hash.new, T::Hash[Integer, T::Set[Domain]])
  end

  protected

  sig { params(block: BB::Block).void }
  def transfer(block)
    # NOTE: stub
  end

  private

  sig { void }
  def run_forwards
    # initialize all nodes
    @out[CFG::ENTRY] = @boundary
    @cfg.each_block { |b|
      if b.number == CFG::ENTRY then next end
      @out[b.number] = @init
    }

    # iterate
    changed = T.let(true, T::Boolean)
    while changed
      changed = false
      @cfg.each_block { |b|
        if b.number == CFG::ENTRY then next end

        old_out = @out[b.number]
        # NOTE: purely to appease sorbet
        if not old_out then raise("OUT set for #{b.number} was nil") end

        transfer(b)

        new_out = @out[b.number]
        # NOTE: purely to appease sorbet
        if not new_out then raise("New OUT set for #{b.number} is nil") end

        if old_out.length != new_out.length
          changed = true
        end
      }
    end
  end

  sig { void }
  def run_backwards
    # initialize all nodes
    @in[CFG::EXIT] = @boundary
    @cfg.each_block { |b|
      if b.number == CFG::EXIT then next end
      @in[b.number] = @init
    }

    # iterate
    changed = T.let(true, T::Boolean)
    while changed
      changed = false
      @cfg.each_block { |b|
        if b.number == CFG::EXIT then next end

        old_in = @in[b.number]
        # NOTE: purely to appease sorbet
        if not old_in then raise("IN set for #{b.number} was nil") end

        transfer(b)

        new_in = @in[b.number]
        # NOTE: purely to appease sorbet
        if not new_in then raise("New IN set for #{b.number} is nil") end

        if old_in.length != new_in.length
          changed = true
        end
      }
    end
  end
end
