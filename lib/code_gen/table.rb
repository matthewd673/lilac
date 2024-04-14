# typed: strict
require "sorbet-runtime"
require_relative "code_gen"
require_relative "instruction"
require_relative "pattern"
require_relative "../il"

class CodeGen::Table
  extend T::Sig

  include CodeGen
  include CodeGen::Pattern

  Rule = T.type_alias { T.any(IL::Statement, IL::Expression, IL::Value) }

  TreeTransform = T.type_alias {
    T.proc.params(arg0: IL::ILObject, arg1: Method)
      .returns(T::Array[CodeGen::Instruction])
  }

  class RuleValue # TODO: there has to be a better name for this
    extend T::Sig

    sig { returns(Integer) }
    attr_reader :cost
    sig { returns(TreeTransform) }
    attr_reader :transform

    sig { params(cost: Integer, transform: TreeTransform).void }
    def initialize(cost, transform)
      @cost = cost
      @transform = transform
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

  sig { params(object: IL::ILObject).returns(T::Array[Instruction]) }
  def transform(object)
    # find all rules that could apply to this object
    rules = find_rules_for_object(object)
    if rules.empty?
      raise("No rules found for object #{object}")
    end

    # sort rules by cost (cheapest at index 0)
    rules.sort!

    # apply the lowest-cost rule to the object
    return apply_rule(T.unsafe(rules[0]), object, method(:transform))
  end

  protected

  sig { params(rule: Rule, cost: Integer, transform: TreeTransform)
          .void }
  def add_rule(rule, cost, transform)
    @rules[rule] = RuleValue.new(cost, transform)
  end

  private

  sig { params(rule: Rule, object: IL::ILObject, recursive_method: Method)
          .returns(T::Array[Instruction]) }
  def apply_rule(rule, object, recursive_method)
    value = @rules[rule]
    if not value
      raise("Rule does not exist in this table: #{rule}")
    else
      value.transform.call(object, recursive_method)
    end
  end

  sig { params(object: IL::ILObject).returns(T::Array[Rule]) }
  def find_rules_for_object(object)
    rules = []

    each_rule { |r|
      if matches?(r, object)
        rules.push(r)
      end
    }

    return rules
  end

  sig { params(rule: Rule, object: IL::ILObject).returns(T::Boolean) }
  def matches?(rule, object)
    case rule
    # WILDCARDS
    # Statement wildcards
    when Pattern::DefinitionWildcard
      return (object.is_a?(IL::Definition) and matches?(rule.rhs, object.rhs))
    when Pattern::StatementWildcard
      return object.is_a?(IL::Statement)
    # Right-hand side wildcard
    when Pattern::RhsWildcard
      return (object.is_a?(IL::Expression) or object.is_a?(IL::Value))
    # Expression wildcards
    when Pattern::BinaryOpWildcard
      if not object.is_a?(IL::BinaryOp)
        false
      end
      object = T.cast(object, IL::BinaryOp)
      matches?(rule.left, object.left) and matches?(rule.right, object.right)
    when Pattern::UnaryOpWildcard
      if not object.is_a?(IL::UnaryOp)
        false
      end
      object = T.cast(object, IL::UnaryOp)
      matches?(rule.value, object.value)
    when Pattern::ExpressionWildcard
      return object.is_a?(IL::Expression)
    # Value wildcards
    when Pattern::IDWildcard
      return object.is_a?(IL::ID)
    when Pattern::ConstantWildcard
      return object.is_a?(IL::Constant)
    when Pattern::IntegerConstantWildcard
      return (object.is_a?(IL::Constant) and
              case object.type # match with the four integer types
              when IL::Type::U8 then true
              when IL::Type::I16 then true
              when IL::Type::I32 then true
              when IL::Type::I64 then true
              else false
              end and
              constant_value_matches?(rule.value, object.value))
    when Pattern::FloatConstantWildcard
      return (object.is_a?(IL::Constant) and
              case object.type # match with the two floating point types
              when IL::Type::F32 then true
              when IL::Type::F64 then true
              else false
              end and
              constant_value_matches?(rule.value, object.value))
    when Pattern::ValueWildcard
      return object.is_a?(IL::Value)
    # NON-WILDCARDS
    # TODO: implement non-wildcard matches
    when IL::BinaryOp
      return (object.is_a?(IL::BinaryOp) and rule.op == object.op and
        matches?(rule.left, object.left) and matches?(rule.right, object.right))
    when IL::UnaryOp
      return (object.is_a?(IL::UnaryOp) and rule.op == object.op and
        matches?(rule.value, object.value))
    end

    raise("Unsupported pattern match between \"#{rule}\" and \"#{object}\"")
  end

  sig { params(rule: T.any(Pattern::ConstantValueWildcard, T.untyped),
               value: T.untyped)
          .returns(T::Boolean) }
  def constant_value_matches?(rule, value)
    case rule
      when Pattern::ConstantValueWildcard then return true
      else return rule == value
    end
  end
end
