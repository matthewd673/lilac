# typed: strict
require "sorbet-runtime"
require "set"
require_relative "analysis"
require_relative "analysis_pass"
require_relative "cfg"

class Analysis::DFA < Analysis::AnalysisPass
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
               init: T::Set[Domain]).void }
  def initialize(direction, boundary, init)
    # NOTE: should always be overwritten by subclasses
    @id = T.let("dfa", String)
    @description = T.let("Generic data flow analysis", String)
    @level = T.let(-1, Integer)

    @direction = direction
    @boundary = boundary
    @init = init

    @out = T.let(Hash.new, T::Hash[Integer, T::Set[Domain]])
    @in = T.let(Hash.new, T::Hash[Integer, T::Set[Domain]])
    @gen = T.let(Hash.new, T::Hash[Integer, T::Set[Domain]])
    @kill = T.let(Hash.new, T::Hash[Integer, T::Set[Domain]])
  end

  sig { params(program: IL::Program).void }
  def run(program)
    blocks = BB::create_blocks(program)
    cfg = CFG.new(blocks)

    run_dfa(cfg)
  end

  protected

  sig { params(cfg: CFG).void }
  def run_dfa(cfg)
    case @direction
    when Direction::Forwards then run_forwards(cfg)
    when Direction::Backwards then run_backwards(cfg)
    else T.absurd(@direction)
    end
  end

  sig { params(block: BB::Block).void }
  def transfer(block)
    raise("Transfer function is unimplemented for #{@id}")
  end

  private

  sig { params(cfg: CFG).void }
  def run_forwards(cfg)
    # initialize all nodes
    @out[CFG::ENTRY] = @boundary
    cfg.each_block { |b|
      if b.number == CFG::ENTRY then next end
      @out[b.number] = @init
    }

    # iterate
    changed = T.let(true, T::Boolean)
    while changed
      changed = false
      cfg.each_block { |b|
        if b.number == CFG::ENTRY then next end

        old_out = T.unsafe(@out[b.number])
        transfer(b)
        new_out = T.unsafe(@out[b.number])
        if old_out.length != new_out.length
          changed = true
        end
      }
    end
  end

  sig { params(cfg: CFG).void }
  def run_backwards(cfg)
    # initialize all nodes
    @in[CFG::EXIT] = @boundary
    cfg.each_block { |b|
      if b.number == CFG::EXIT then next end
      @in[b.number] = @init
    }

    # iterate
    changed = T.let(true, T::Boolean)
    while changed
      changed = false
      cfg.each_block { |b|
        if b.number == CFG::EXIT then next end

        old_in = T.unsafe(@in[b.number])
        transfer(b)
        new_in = T.unsafe(@in[b.number])
        if old_in.length != new_in.length
          changed = true
        end
      }
    end
  end
end
