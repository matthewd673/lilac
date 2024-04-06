# typed: strict
require "sorbet-runtime"
require_relative "analysis"
require_relative "bb"
require_relative "cfg"
require_relative "dfa"

class Analysis::LiveVars < Analysis::DFA
  extend T::Sig
  extend T::Generic

  # Domain = variable names
  Domain = type_member {{ lower: String }}

  sig { params(cfg: CFG).void }
  def initialize(cfg)
    super(Direction::Forwards,
          Set[],
          Set[],
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
    # union of IN[S] for all successors S of B
    u = T.let(Set[], T::Set[Domain])

    @cfg.each_successor(block) { |s|
      u = u | get_set(@in, s)
    }

    return u
  end

  sig { params(block: BB).returns(T::Set[Domain]) }
  def transfer(block)
    # union of GEN[B] and (OUT[b] - KILL[b])
    return get_set(@gen, block) |
      (get_set(@out, block) - get_set(@kill, block))
  end

  private

  sig { params(b: BB).void }
  def init_sets(b)
    # initialize gen and kill sets
    @gen[b.id] = Set[]
    @kill[b.id] = Set[]

    b.each_stmt { |s|
      # TODO: someday will need to account for function calls
      if not s.is_a?(IL::Definition)
        next
      end

      # find vars that may be upwardly exposed by the stmt
      # add these to the GEN set
      ue = find_vars(s)
      ue.each { |var|
        b_kill = T.unsafe(@kill[b.id])
        if not b_kill.include?(var)
          T.unsafe(@gen[b.id]).add(var)
        end
      }

      # add lhs to KILL set
      T.unsafe(@kill[b.id]).add(s.id)
    }
  end

  sig { params(node: T.any(IL::Statement, IL::Expression, IL::Value))
    .returns(T::Set[String])}
  def find_vars(node)
    if node.is_a?(IL::Definition)
      return find_vars(node.rhs)
    elsif node.is_a?(IL::BinaryOp)
      return find_vars(node.left) | find_vars(node.right)
    elsif node.is_a?(IL::UnaryOp)
      return find_vars(node.value)
    elsif node.is_a?(IL::ID)
      return Set[node.name]
    # TODO: will someday need a case for function calls
    end

    return Set[] # base case: empty set -- no variables found
  end
end
