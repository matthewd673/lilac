# typed: strict
# frozen_string_literal: true

require "sorbet-runtime"
require_relative "optimization_pass"
require_relative "../il"

module Lilac
  module Optimization
    # SimplifyRedundantBinops is an optimization that removes binary ops that
    # have no effect, like multiplying a variable by +1+.
    class SimplifyRedundantBinops < OptimizationPass
      extend T::Sig

      sig { override.returns(String) }
      def self.id
        "simplify_redundant_binops"
      end

      sig { override.returns(String) }
      def self.description
        "Simplify binary operators that have no effect (i.e.: x + 0)"
      end

      sig { override.returns(Integer) }
      def self.level
        0
      end

      sig { override.returns(UnitType) }
      def self.unit_type
        UnitType::BasicBlock
      end

      sig { params(block: Analysis::BB).void }
      def initialize(block)
        @block = block
      end

      sig { override.void }
      def run!
        # find all binops (which can only occur in Definitions)
        @block.stmt_list.each do |s|
          if !s.is_a?(IL::Definition) || !s.rhs.is_a?(IL::BinaryOp)
            next
          end

          new = simplify_binop(T.cast(s.rhs, IL::BinaryOp))
          # if simplify_binop returned nil, there is no way to simplify so skip
          unless new
            next
          end

          # else, replace the binop with the new value
          s.rhs = new
        end
      end

      private

      sig { params(binop: IL::BinaryOp).returns(T.nilable(IL::Value)) }
      def simplify_binop(binop)
        case binop.op
        when IL::BinaryOp::Operator::ADD
          # check for adding 0
          if const?(binop.left, 0)
            return binop.right
          elsif const?(binop.right, 0)
            return binop.left
          end
        when IL::BinaryOp::Operator::SUB
          # check for subtracting 0
          if const?(binop.right, 0) # not associative
            return binop.left
          end
        when IL::BinaryOp::Operator::MUL
          # check for mul by 1
          if const?(binop.left, 1)
            return binop.right
          elsif const?(binop.right, 1)
            return binop.left
          end

          # check for mul by 0
          if const?(binop.left, 0)
            return binop.left # return the zero
          elsif const?(binop.right, 0)
            return binop.right # same idea
          end
        when IL::BinaryOp::Operator::DIV
          # check for div by 1
          if const?(binop.right, 1) # not associative
            return binop.left
          end
        when IL::BinaryOp::Operator::BOOL_OR
          # check for or with something non-zero (which is always true)
          if const?(binop.left, 0, neg: true)
            return binop.left # return the non-zero
          elsif const?(binop.right, 0, neg: true)
            return binop.right # return the non-zero
          end
        when IL::BinaryOp::Operator::BOOL_AND
          # check for and with something zero (which is always false)
          if const?(binop.left, 0)
            return binop.left # return the zero because thats what it evals to
          elsif const?(binop.right, 0)
            return binop.right # same idea
          end
        end

        nil
      end

      sig do
        params(value: IL::Value, const: T.untyped,
               neg: T::Boolean).returns(T::Boolean)
      end
      def const?(value, const, neg: false)
        case value
        # NOTE: the below should work for any numeric type
        when IL::Constant
          ans = value.value == const
          if neg
            return !ans
          end

          ans
        else false
        end
      end
    end
  end
end
