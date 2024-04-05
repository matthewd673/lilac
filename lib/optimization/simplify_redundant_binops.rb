# typed: strict
require "sorbet-runtime"
require_relative "optimization"
require_relative "optimization_pass"
require_relative "../il"

include Optimization

class Optimization::SimplifyRedundantBinops < OptimizationPass
  extend T::Sig

  sig { void }
  def initialize
    @id = T.let("simplify_redundant_binops", String)
    @description = T.let(
      "Simplify binary operators that have no effect (i.e.: x + 0)", String)
    @level = T.let(0, Integer)
  end

  sig { params(stmt_list: T::Array[IL::Statement]).void }
  def run(stmt_list)
    # find all binops (which can only occur in Definitions)
    stmt_list.each { |s|
      if (not s.is_a?(IL::Definition)) or (not s.rhs.is_a?(IL::BinaryOp))
          next
      end

      new = simplify_binop(T.cast(s.rhs, IL::BinaryOp))
      # returns nil if the binop cannot be simplified
      if not new then next end

      # else, replace the binop with the new value
      s.rhs = new
    }
  end

  private

  sig { params(binop: IL::BinaryOp).returns(T.nilable(IL::Value)) }
  def simplify_binop(binop)
    case binop.op
    when IL::BinaryOp::Operator::ADD
      # check for adding 0
      if is_const?(binop.left, 0)
        return binop.right
      elsif is_const?(binop.right, 0)
        return binop.left
      end
    when IL::BinaryOp::Operator::SUB
      # check for subtracting 0
      if is_const?(binop.right, 0) # not associative
        return binop.left
      end
    when IL::BinaryOp::Operator::MUL
      # check for mul by 1
      if is_const?(binop.left, 1)
        return binop.right
      elsif is_const?(binop.right, 1)
        return binop.left
      end

      # check for mul by 0
      if is_const?(binop.left, 0)
        return binop.left # return the zero
      elsif is_const?(binop.right, 0)
        return binop.right # same idea
      end
    when IL::BinaryOp::Operator::DIV
      # check for div by 1
      if is_const?(binop.right, 1) # not associative
        return binop.left
      end
    when IL::BinaryOp::Operator::OR
      # check for or with something non-zero (which is always true)
      if is_const?(binop.left, 0, neg: true)
        return binop.left # return the non-zero
      elsif is_const?(binop.right, 0, neg: true)
        return binop.right # return the non-zero
      end
    when IL::BinaryOp::Operator::AND
      # check for and with something zero (which is always false)
      if is_const?(binop.left, 0)
        return binop.left # return the zero because thats what it evals to
      elsif is_const?(binop.right, 0)
        return binop.right # same idea
      end
    end

    return nil
  end

    sig { params(value: IL::Value, const: T.untyped, neg: T::Boolean).returns(T::Boolean) }
  def is_const?(value, const, neg: false)
    case value
    # NOTE: the below should work for any numeric type
    when IL::Constant
      ans = value.value == const
      if neg
        return !ans
      end
      return ans
    else false
    end
  end
end
