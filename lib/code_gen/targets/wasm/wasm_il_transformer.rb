# typed: strict
require "sorbet-runtime"
require_relative "wasm"
require_relative "../../il_transformer"
require_relative "../../../symbol_table"
require_relative "type"
require_relative "instructions/instructions"

class CodeGen::Targets::Wasm::WasmILTransformer < CodeGen::ILTransformer
  extend T::Sig

  include CodeGen
  include CodeGen::Targets::Wasm

  WasmTreeTransform = T.type_alias {
    T.proc.params(arg0: IL::ILObject, arg1: WasmILTransformer)
      .returns(T::Array[CodeGen::Instruction])
  }

  sig { params(symbol_table: SymbolTable).void }
  def initialize(symbol_table)
    super()
    @symbol_table = symbol_table
    @rules = RULES
  end

  sig { params(object: IL::ILObject).returns(T::Array[CodeGen::Instruction]) }
  def transform(object)
    super(object)
  end

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
  def self.signed?(type)
    case type
    when IL::Type::I16 then true
    when IL::Type::I32 then true
    when IL::Type::I64 then true
    else false
    end
  end

  sig { params(type: IL::Type).returns(T::Boolean) }
  def self.unsigned?(type)
    case type
    when IL::Type::U8 then true
    else false
    end
  end

  sig { params(type: IL::Type).returns(T::Boolean) }
  def self.float?(type)
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

  private

  RULES = T.let({
    # STATEMENT RULES
    # definition
    Pattern::DefinitionWildcard.new(Pattern::RhsWildcard.new) =>
      -> (t, o) {
        rhs = t.transform(o.rhs)

        [rhs,
         Instructions::LocalSet.new(o.id.name)]
      },
    # void call
    IL::VoidCall.new(Pattern::CallWildcard.new) =>
      -> (t, o) {
        call = t.transform(o.call)

        [call]
      },
    # EXPRESSION RULES
    # binary ops
    # addition
    IL::BinaryOp.new(IL::BinaryOp::Operator::ADD,
                     Pattern::ValueWildcard.new,
                     Pattern::ValueWildcard.new) =>
      -> (t, o) {
        left = t.transform(o.left)
        right = t.transform(o.right)
        type = t.get_type(o.left)
        [left, right, Instructions::Add.new(type)]
      },
    # subtraction
    IL::BinaryOp.new(IL::BinaryOp::Operator::SUB,
                     Pattern::ValueWildcard.new,
                     Pattern::ValueWildcard.new) =>
      -> (t, o) {
        left = t.transform(o.left)
        right = t.transform(o.right)
        type = t.get_type(o.left)
        [left, right, Instructions::Subtract.new(type)]
      },
    # multiplication
    IL::BinaryOp.new(IL::BinaryOp::Operator::MUL,
                     Pattern::ValueWildcard.new,
                     Pattern::ValueWildcard.new) =>
      -> (t, o) {
        left = t.transform(o.left)
        right = t.transform(o.right)
        type = t.get_type(o.left)
        [left, right, Instructions::Multiply.new(type)]
      },
    # division
    IL::BinaryOp.new(IL::BinaryOp::Operator::DIV,
                     Pattern::ValueWildcard.new,
                     Pattern::ValueWildcard.new) =>
      -> (t, o) {
        left = t.transform(o.left)
        right = t.transform(o.right)

        il_type = t.get_il_type(o.left)

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
      },
    # equality
    # normal equality
    IL::BinaryOp.new(IL::BinaryOp::Operator::EQ,
              Pattern::ValueWildcard.new,
              Pattern::ValueWildcard.new) =>
      -> (t, o) {
        left = t.transform(o.left)
        right = t.transform(o.right)

        type = t.get_type(o.left)

        [left, right, Instructions::Equal.new(type)]
      },
    # eqz (for 0 on left or right)
    IL::BinaryOp.new(IL::BinaryOp::Operator::EQ,
                     Pattern::IntegerConstantWildcard.new(0),
                     Pattern::ValueWildcard.new) =>
      -> (t, o) {
        right = t.transform(o.right)

        # lookup type based on constant
        il_type = t.get_il_type(o.left)
        type = Instructions::to_integer_type(il_type)

        [right, Instructions::EqualZero.new(type)]
      },
    IL::BinaryOp.new(IL::BinaryOp::Operator::EQ,
                     Pattern::ValueWildcard.new,
                     Pattern::IntegerConstantWildcard.new(0)) =>
      -> (t, o) {
        left = t.transform(o.left)

        # lookup type based on constant
        il_type = t.get_il_type(o.right)
        type = Instructions::to_integer_type(il_type)

        [left, Instructions::EqualZero.new(type)]
      },
    # less than
    IL::BinaryOp.new(IL::BinaryOp::Operator::LT,
                     Pattern::ValueWildcard.new,
                     Pattern::ValueWildcard.new) =>
      -> (t, o) {
        left = t.transform(o.left)
        right = t.transform(o.right)

        il_type = t.get_il_type(o.left)

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
      },
    # CALL RULES
    Pattern::CallWildcard.new =>
      -> (t, o) {
        instructions = []

        # push all arguments
        o.args.each { |a|
          instructions.concat(t.transform(a))
        }

        instructions.push(Instructions::Call.new(o.func_name))
        instructions
      },
    IL::Return.new(Pattern::ValueWildcard.new) =>
      -> (t, o) {
        value = t.transform(o.value)

        [value, Instructions::Return.new]
      },
    # VALUE RULES
    Pattern::IDWildcard.new =>
      -> (t, o) {
        [Instructions::LocalGet.new(o.name)]
      },
    Pattern::ConstantWildcard.new =>
      -> (t, o) {
        # produce nothing for void constants
        # these are only used by return statements
        if o.type == IL::Type::Void
          return []
        end

        type = Instructions::to_wasm_type(o.type)
        [Instructions::Const.new(type, o.value)]
      },
  }, T::Hash[IL::ILObject, Transform])
end
