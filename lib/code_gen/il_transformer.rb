# typed: strict
require "sorbet-runtime"
require_relative "code_gen"
require_relative "instruction"
require_relative "pattern"
require_relative "../il"

class CodeGen::ILTransformer
  extend T::Sig

  include CodeGen
  include CodeGen::Pattern

  Transform = T.type_alias {
    T.proc.params(arg0: CodeGen::ILTransformer, arg1: IL::ILObject)
      .returns(T::Array[CodeGen::Instruction])
  }

  sig { void }
  def initialize
    @rules = T.let(Hash.new, T::Hash[IL::ILObject, Transform])
  end

  sig { params(block: T.proc.params(arg0: IL::ILObject).void).void }
  def each_rule(&block)
    @rules.keys.each(&block)
  end

  sig { params(object: IL::ILObject).returns(T::Array[Instruction]) }
  def transform(object)
    # find all rules that could apply to this object
    rule = find_rule_for_object(object)
    if not rule
      raise("No rules found for object #{object}")
    end

    # apply the rule to the object
    return apply_transform(rule, object, self)
  end

  private

  sig { params(transform: Transform,
               object: IL::ILObject,
               transformer: CodeGen::ILTransformer)
          .returns(T::Array[Instruction]) }
  def apply_transform(transform, object, transformer)
    transform.call(transformer, object)
  end

  sig { params(object: IL::ILObject).returns(T.nilable(Transform)) }
  def find_rule_for_object(object)
    rule = T.let(nil, T.nilable(Transform))
    each_rule { |r|
      if matches?(r, object)
        rule = @rules[r]
        break
      end
    }
    rule
  end

  sig { params(rule: IL::ILObject, object: IL::ILObject).returns(T::Boolean) }
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
    when Pattern::CallWildcard
      return object.is_a?(IL::Call)
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
    when Pattern::SignedConstantWildcard
      return (object.is_a?(IL::Constant) and
              case object.type
              when IL::Type::I16 then true
              when IL::Type::I32 then true
              when IL::Type::I64 then true
              else false
              end and
              constant_value_matches?(rule.value, object.value))
    when Pattern::UnsignedConstantWildcard
      return (object.is_a?(IL::Constant) and
              case object.type
              when IL::Type::U8 then true
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
    # Statements
    when IL::VoidCall
      return (object.is_a?(IL::VoidCall) and matches?(rule.call, object.call))
    when IL::Return
      return (object.is_a?(IL::Return) and matches?(rule.value, object.value))
    # Expressions
    # TODO: implement non-wildcard matches
    when IL::BinaryOp
      return (object.is_a?(IL::BinaryOp) and rule.op == object.op and
        matches?(rule.left, object.left) and matches?(rule.right, object.right))
    when IL::UnaryOp
      return (object.is_a?(IL::UnaryOp) and rule.op == object.op and
        matches?(rule.value, object.value))
    when IL::Return
      return (object.is_a?(IL::Return) and matches?(rule.value, object.value))
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
