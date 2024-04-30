# typed: strict
# frozen_string_literal: true

require "sorbet-runtime"
require_relative "analysis"
require_relative "bb"
require_relative "cfg"
require_relative "dfa"
require_relative "cfg_facts"

module Analysis
  class LiveVars < Analysis::DFA
    extend T::Sig
    extend T::Generic

    # Domain = variable names
    Domain = type_member { { fixed: String } }

    sig { params(cfg: CFG).void }
    def initialize(cfg)
      super(Direction::Backwards,
            Set[],
            Set[],
            cfg)
    end

    sig { returns(CFGFacts[Domain]) }
    def run
      @cfg.each_block do |b|
        init_sets(b)
      end

      super
    end

    protected

    sig { params(block: BB).returns(T::Set[Domain]) }
    def meet(block)
      # union of IN[S] for all successors S of B
      u = T.let(Set[], T::Set[Domain])

      @cfg.each_successor(block) do |s|
        u |= get_set(@in, s)
      end

      u
    end

    sig { params(block: BB).returns(T::Set[Domain]) }
    def transfer(block)
      # union of GEN[B] and (OUT[b] - KILL[b])
      get_set(@gen, block) |
        (get_set(@out, block) - get_set(@kill, block))
    end

    private

    sig { params(b: BB).void }
    def init_sets(b)
      # initialize gen and kill sets
      @gen[b] = Set[]
      @kill[b] = Set[]

      b.stmt_list.each do |s|
        unless s.is_a?(IL::Definition)
          next
        end

        # find vars that may be upwardly exposed by the stmt
        # add these to the GEN set
        ue = find_vars(s)
        ue.each do |var|
          b_kill = T.unsafe(@kill[b])
          unless b_kill.include?(var)
            T.unsafe(@gen[b]).add(var)
          end
        end

        # add lhs to KILL set
        T.unsafe(@kill[b]).add(s.id)
      end
    end

    sig do
      params(node: T.any(IL::Statement, IL::Expression, IL::Value))
        .returns(T::Set[String])
    end
    def find_vars(node)
      case node
      when IL::Definition
        return find_vars(node.rhs)
      when IL::BinaryOp
        return find_vars(node.left) | find_vars(node.right)
      when IL::UnaryOp
        return find_vars(node.value)
      when IL::ID
        return Set[node.name]
        # TODO: will someday need a case for function calls
      end

      Set[] # base case: empty set -- no variables found
    end
  end
end
