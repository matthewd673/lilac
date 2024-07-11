# typed: strict
# frozen_string_literal: true

require "sorbet-runtime"
require_relative "bb"
require_relative "cfg"
require_relative "dfa"
require_relative "cfg_facts"

module Lilac
  module Analysis
    class LiveVars < Analysis::DFA
      extend T::Sig
      extend T::Generic

      # Domain = ids
      Domain = type_member { { fixed: IL::ID } }

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
        # adapted from Figure 8.14 in Cooper & Torczon 2nd edition
        @gen[b] = Set[] # UEVar
        @kill[b] = Set[] # VarKill

        # we want to examine not only the block stmt list but also its exit
        exit_arr = b.exit ? [b.exit] : []
        examined_stmts = b.stmt_list + exit_arr

        examined_stmts.each do |s|
          unless s.is_a?(IL::Definition)
            next
          end

          # add all ids on the rhs to GEN unless they're already in KILL
          rhs_vars = find_rhs_ids(s)
          rhs_vars.each do |v|
            unless T.unsafe(@kill[b]).include?(v)
              T.unsafe(@gen[b]).add(v)
            end
          end

          # add the id being defined into KILL
          T.unsafe(@kill[b]).add(s.id)
        end
      end

      sig do
        params(node: T.any(IL::Statement, IL::Expression, IL::Value))
          .returns(T::Set[IL::ID])
      end
      def find_rhs_ids(node)
        case node
        when IL::Definition
          return find_rhs_ids(node.rhs)
        when IL::BinaryOp
          return find_rhs_ids(node.left) | find_rhs_ids(node.right)
        when IL::UnaryOp
          return find_rhs_ids(node.value)
        when IL::ID
          return Set[node]
        when IL::JumpZero
          return find_rhs_ids(node.cond)
        when IL::JumpNotZero
          return find_rhs_ids(node.cond)
        when IL::Conversion
          return find_rhs_ids(node.value)
        when IL::Call
          ids = Set[]
          node.args.each do |a|
            ids |= find_rhs_ids(a)
          end
          return ids
        when IL::Constant
          return Set[]
        when IL::Phi
          ids = Set[]
          node.ids.each do |i|
            ids |= find_rhs_ids(i) # this recursive call is overkill but oh well
          end
          return ids
        end

        # this should never hit but it will ensure that new IL objects are
        # considered
        raise "Unexpected IL object when running find_rhs_ids: "\
              "#{node} (#{node.class})."
      end
    end
  end
end
