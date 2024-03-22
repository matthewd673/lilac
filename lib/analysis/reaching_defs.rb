# typed: strict
require "sorbet-runtime"
require "set"
require_relative "analysis"
require_relative "cfg"
require_relative "dfa"

include Analysis

class Analysis::ReachingDefs < DFA
  extend T::Sig
  extend T::Generic

  # Domain = definitions
  Domain = type_member {{ lower: String }}

  sig { void }
  def initialize
    super(Direction::Forwards,
          Set[],
          Set[])

    @id = T.let("reaching_defs", String)
    @description = T.let("Reaching definitions analysis", String)

    @all_defs = T.let(Set[], T::Set[Domain])
  end

  sig { params(program: IL::Program).void }
  def run(program)
    blocks = BB::create_blocks(program)
    cfg = CFG.new(blocks)

    @all_defs = compute_all_defs(program)

    blocks.each { |b|
      init_sets(b)
    }

    run_dfa(cfg)
  end

  protected

  sig { params(block: BB::Block, cfg: CFG).void }
  def transfer(block, cfg)
    n = block.number
    @in[n] = meet(block, cfg)
    @out[n] = T.unsafe(@gen[n]) | (T.unsafe(@in[n]) - T.unsafe(@kill[n]))
  end

  sig { params(block: BB::Block, cfg: CFG).returns(T::Set[Domain]) }
  def meet(block, cfg)
    # TODO
  end

  private

  sig { params(b: BB::Block).void }
  def init_sets(b)
    # initialize gen and kill sets
    @gen[b.number] = Set[]
    @kill[b.number] = Set[]

    # find all definitions in block
    b.each_stmt { |s|
      # only definitions are relevant
      if not s.is_a?(IL::Definition)
        next
      end

      key = s.id.key
      T.unsafe(@gen[b.number]).add(key)
    }

    # any def not in this block is killed here
    @kill[b.number] = @all_defs - T.unsafe(@gen[b.number])
  end

  sig { params(program: IL::Program).returns(T::Set[Domain]) }
  def compute_all_defs(program)
    all = Set[]

    program.each_stmt { |s|
      # only definitions are relevant
      if not s.is_a?(IL::Definition)
        next
      end

      key = s.id.key
      T.unsafe(all).add(key)
    }

    return all
  end
end