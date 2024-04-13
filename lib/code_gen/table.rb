# typed: strict
require "sorbet-runtime"
require_relative "code_gen"
require_relative "instruction"
require_relative "pattern"

class CodeGen::Table
  extend T::Sig

  include CodeGen
  include CodeGen::Pattern

  Rule = T.type_alias { T.any(IL::Statement, IL::Expression, IL::Value) }

  class RuleValue # TODO: there has to be a better name for this
    extend T::Sig

    sig { returns(Integer) }
    attr_reader :cost
    sig { returns(CodeGen::Instruction) }
    attr_reader :instruction

    sig { params(cost: Integer, instruction: CodeGen::Instruction).void }
    def initialize(cost, instruction)
      @cost = cost
      @instruction = instruction
    end
  end

  sig { void }
  def initialize
    @rules = T.let(Hash.new, T::Hash[Rule, RuleValue])
  end

  sig { params(block: T.proc.params(arg0: Rule).void).void }
  def each_rule(&block)
    @rules.keys.each(&block)
  end

  sig { params(rule: Rule).returns(T.nilable(Instruction)) }
  def get_rule_instruction(rule)
    value = @rules[rule]
    if not value
      nil
    else
      value.instruction
    end
  end

  sig { params(rule: Rule).returns(T::Array[Rule]) }
  def find_rule_matches(rule)
    rules = []

    each_rule { |r|
      if matches?(r, rule)
        rules.push(r)
      end
    }

    return rules
  end

  protected

  sig { params(rule: Rule, cost: Integer, instruction: Instruction).void }
  def add_rule(rule, cost, instruction)
    @rules[rule] = RuleValue.new(cost, instruction)
  end

  private

  sig { params(a: Rule, b: Rule).returns(T::Boolean) }
  def matches?(a, b)
    case a
    # match wildcards (easy)
    when Pattern::StatementWildcard
      return b.is_a?(IL::Statement)
    when Pattern::BinaryOpWildcard
      if not b.is_a?(IL::BinaryOp)
        false
      end
      b = T.cast(b, IL::BinaryOp)
      matches?(a.left, b.left) and matches?(a.right, b.right)
    when Pattern::UnaryOpWildcard
      if not b.is_a?(IL::UnaryOp)
        false
      end
      b = T.cast(b, IL::UnaryOp)
      matches?(a.value, b.value)
    when Pattern::ExpressionWildcard
      return b.is_a?(IL::Expression)
    when Pattern::IDWildcard
      return b.is_a?(IL::ID)
    when Pattern::ConstantWildcard
      return b.is_a?(IL::Constant)
    when Pattern::ValueWildcard
      return b.is_a?(IL::Value)
    # TODO: implement non-wildcard matches
    end

    raise("Unsupported pattern match between \"#{a}\" and \"#{b}\"")
  end
end
