# typed: strict
require "sorbet-runtime"
require_relative "wasm"
require_relative "../../table"
require_relative "../../../symbol_table"
require_relative "type"
require_relative "instructions/instructions"

class CodeGen::Targets::Wasm::Table < CodeGen::Table
  extend T::Sig

  include CodeGen
  include CodeGen::Targets::Wasm

  TypeLookup = T.type_alias { T.proc.params(arg0: String).returns(IL::Type) }

  sig { params(symbol_table: SymbolTable).void }
  def initialize(symbol_table)
    super()
    @symbol_table = symbol_table
    define_rules
  end

  sig { params(object: IL::ILObject).returns(T::Array[CodeGen::Instruction]) }
  def transform(object)
    super(object)
  end

  private

  sig { params(value: IL::Value).returns(IL::Type) }
  def get_il_type(value)
    case value
    when IL::ID
      symbol = @symbol_table.lookup(value.key)
      if not symbol
        raise "Symbol #{value} not in symbol table"
      end
      return symbol.type
    when IL::Constant then value.type
    when IL::Value
      raise "Cannot get type of IL::Value stub class"
    end
  end

  sig { params(type: IL::Type).returns(T::Boolean) }
  def signed?(type)
    case type
    when IL::Type::I16 then true
    when IL::Type::I32 then true
    when IL::Type::I64 then true
    else false
    end
  end

  sig { params(type: IL::Type).returns(T::Boolean) }
  def unsigned?(type)
    case type
    when IL::Type::U8 then true
    else false
    end
  end

  sig { params(type: IL::Type).returns(T::Boolean) }
  def float?(type)
    case type
    when IL::Type::F32 then true
    when IL::Type::F64 then true
    else false
    end
  end

  sig { params(rhs: T.any(IL::Expression, IL::Value)).returns(Type) }
  def get_type(rhs)
    case rhs
    when IL::BinaryOp
      return get_type(rhs.left) # left and right should always match
    when IL::UnaryOp
      return get_type(rhs.value)
    when IL::ID
      symbol = @symbol_table.lookup(rhs.key)
      if not symbol
        raise "Symbol #{rhs} not in symbol table"
      end
      return Instructions::to_wasm_type(symbol.type)
    when IL::Constant
      return Instructions::to_wasm_type(rhs.type)
    else
      raise "Unable to determine type of #{rhs}"
    end
  end

  sig { void }
  def define_rules
    # TODO: costs for rules have not had any consideration yet

    # STATEMENT RULES
    # definition
    add_rule(Pattern::DefinitionWildcard.new(Pattern::RhsWildcard.new),
             0,
             -> (object, recurse) {
               rhs = recurse.call(object.rhs)

               # TODO: this is ugly
               # special case for handling a call to an external void func
               if object.rhs.is_a?(IL::ExternCall) and object.rhs.void
                 return [rhs]
               end

               [rhs,
                Instructions::LocalSet.new(object.id.name)] # TODO: temp
             })

    # EXPRESSION RULES
    # binary ops
    # addition
    add_rule(IL::BinaryOp.new(IL::BinaryOp::Operator::ADD,
                              Pattern::ValueWildcard.new,
                              Pattern::ValueWildcard.new),
             0,
             -> (object, recurse) {
               left = recurse.call(object.left)
               right = recurse.call(object.right)
               type = get_type(object.left)
               [left, right, Instructions::Add.new(type)]
             })
    # subtraction
    add_rule(IL::BinaryOp.new(IL::BinaryOp::Operator::SUB,
                              Pattern::ValueWildcard.new,
                              Pattern::ValueWildcard.new),
             0,
             -> (object, recurse) {
               left = recurse.call(object.left)
               right = recurse.call(object.right)
               type = get_type(object.left)
               [left, right, Instructions::Subtract.new(type)]
             })
    # multiplication
    add_rule(IL::BinaryOp.new(IL::BinaryOp::Operator::MUL,
                              Pattern::ValueWildcard.new,
                              Pattern::ValueWildcard.new),
             0,
             -> (object, recurse) {
               left = recurse.call(object.left)
               right = recurse.call(object.right)
               type = get_type(object.left)
               [left, right, Instructions::Multiply.new(type)]
             })
    # division
    add_rule(IL::BinaryOp.new(IL::BinaryOp::Operator::DIV,
                              Pattern::ValueWildcard.new,
                              Pattern::ValueWildcard.new),
             0,
             -> (object, recurse) {
               left = recurse.call(object.left)
               right = recurse.call(object.right)

               il_type = get_il_type(object.left)

               # choose between div_s, div_u, and div
               div = nil
               if signed?(il_type)
                 type = Instructions::to_integer_type(il_type)
                 div = Instructions::DivideSigned.new(type)
               elsif unsigned?(il_type)
                 type = Instructions::to_integer_type(il_type)
                 div = Instructions::DivideUnsigned.new(type)
               elsif float?(il_type)
                 type = Instructions::to_float_type(il_type)
                 div = Instructions::Divide.new(type)
               end

               [left, right, div]
             })
    # less than
    add_rule(IL::BinaryOp.new(IL::BinaryOp::Operator::LT,
                              Pattern::ValueWildcard.new,
                              Pattern::ValueWildcard.new),
             0,
             -> (object, recurse) {
               left = recurse.call(object.left)
               right = recurse.call(object.right)

               il_type = get_il_type(object.left)

               # choose between lt_s, lt_u, and lt
               lt = nil
               if signed?(il_type)
                 type = Instructions::to_integer_type(il_type)
                 lt = Instructions::LessThanSigned.new(type)
               elsif unsigned?(il_type)
                 type = Instructions::to_integer_type(il_type)
                 lt = Instructions::LessThanUnsigned.new(type)
               elsif float?(il_type)
                 type = Instructions::to_float_type(il_type)
                 lt = Instructions::LessThan.new(type)
               end

               [left, right, lt]
             })
    # CALL RULES
    add_rule(Pattern::CallWildcard.new,
             0,
             -> (object, recurse) {
               instructions = []

               # push all arguments
               object.args.each { |a|
                 instructions.concat(recurse.call(a))
               }

               instructions.push(Instructions::Call.new(object.func_name))
               instructions
             })
    add_rule(IL::Return.new(Pattern::ValueWildcard.new),
             0,
             -> (object, recurse) {
               value = recurse.call(object.value)

               [value, Instructions::Return.new]
             })
    # VALUE RULES
    add_rule(Pattern::IDWildcard.new,
             0,
             -> (object, recurse) {
               [Instructions::LocalGet.new(object.name)]
             })
    add_rule(Pattern::ConstantWildcard.new,
             0,
             -> (object, recurse) {
               type = Instructions::to_wasm_type(object.type)
               [Instructions::Const.new(type, object.value)]
             })
  end
end
