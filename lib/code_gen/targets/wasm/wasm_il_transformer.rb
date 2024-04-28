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

  sig { params(rhs: T.any(IL::Expression, IL::Value)).returns(IL::Type) }
  def get_il_type(rhs)
    case rhs
    when IL::BinaryOp
      return get_il_type(rhs.left) # left and right should always match
    when IL::UnaryOp
      return get_il_type(rhs.value)
    when IL::ID
      symbol = @symbol_table.lookup(rhs.key)
      if not symbol
        raise "Symbol #{rhs} not in symbol table"
      end
      return symbol.type
    when IL::Constant then rhs.type
    else
      raise "Unable to determine type of #{rhs}"
    end
  end

  sig { params(rhs: T.any(IL::Expression, IL::Value)).returns(Type) }
  def get_type(rhs)
    Instructions::to_wasm_type(get_il_type(rhs))
  end

  private

  RULES = T.let({
    # STATEMENT RULES
    # definition
    Pattern::DefinitionWildcard.new(Pattern::RhsWildcard.new) =>
      -> (t, o) {
        instructions = []

        # recurse on rhs then push local set
        instructions.concat(t.transform(o.rhs))
        instructions.push(Instructions::LocalSet.new(o.id.name))

        instructions
      },
    # void call
    IL::VoidCall.new(Pattern::CallWildcard.new) =>
      -> (t, o) {
        t.transform(o.call) # easy, since this stmt just wraps the call expr
      },
    # EXPRESSION RULES
    # binary ops
    # addition
    IL::BinaryOp.new(IL::BinaryOp::Operator::ADD,
                     Pattern::ValueWildcard.new,
                     Pattern::ValueWildcard.new) =>
      -> (t, o) {
        instructions = []

        # translate left, right, and then push op
        instructions.concat(t.transform(o.left))
        instructions.concat(t.transform(o.right))
        type = t.get_type(o.left)
        instructions.push(Instructions::Add.new(type))

        instructions
      },
    # subtraction
    IL::BinaryOp.new(IL::BinaryOp::Operator::SUB,
                     Pattern::ValueWildcard.new,
                     Pattern::ValueWildcard.new) =>
      -> (t, o) {
        instructions = []

        # translate left, right, and then push op
        instructions.concat(t.transform(o.left))
        instructions.concat(t.transform(o.right))
        type = t.get_type(o.left)
        instructions.push(Instructions::Subtract.new(type))

        instructions
      },
    # multiplication
    IL::BinaryOp.new(IL::BinaryOp::Operator::MUL,
                     Pattern::ValueWildcard.new,
                     Pattern::ValueWildcard.new) =>
      -> (t, o) {
        instructions = []

        # translate left, right, and then push op
        instructions.concat(t.transform(o.left))
        instructions.concat(t.transform(o.right))
        type = t.get_type(o.left)
        instructions.push(Instructions::Multiply.new(type))

        instructions
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
        if il_type.signed?
          type = Instructions::to_integer_type(il_type)
          div = Instructions::DivideSigned.new(type)
        elsif il_type.unsigned?
          type = Instructions::to_integer_type(il_type)
          div = Instructions::DivideUnsigned.new(type)
        elsif il_type.float?
          type = Instructions::to_float_type(il_type)
          div = Instructions::Divide.new(type)
        end

        instructions = []
        instructions.concat(left)
        instructions.concat(right)
        instructions.push(div)

        instructions
      },
    # equality
    # eqz (for 0 on left or right)
    IL::BinaryOp.new(IL::BinaryOp::Operator::EQ,
                     Pattern::IntegerConstantWildcard.new(0),
                     Pattern::ValueWildcard.new) =>
      -> (t, o) {
        right = t.transform(o.right)

        # lookup type based on constant
        il_type = t.get_il_type(o.left)
        type = Instructions::to_integer_type(il_type)

        instructions = []
        instructions.concat(right)
        instructions.push(Instructions::EqualZero.new(type))

        instructions
      },
    IL::BinaryOp.new(IL::BinaryOp::Operator::EQ,
                     Pattern::ValueWildcard.new,
                     Pattern::IntegerConstantWildcard.new(0)) =>
      -> (t, o) {
        left = t.transform(o.left)

        # lookup type based on constant
        il_type = t.get_il_type(o.right)
        type = Instructions::to_integer_type(il_type)

        instructions = []
        instructions.concat(left)
        instructions.push(Instructions::EqualZero.new(type))

        instructions
      },
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
    # not equal
    IL::BinaryOp.new(IL::BinaryOp::Operator::NEQ,
              Pattern::ValueWildcard.new,
              Pattern::ValueWildcard.new) =>
      -> (t, o) {
        left = t.transform(o.left)
        right = t.transform(o.right)

        type = t.get_type(o.left)

        [left, right, Instructions::NotEqual.new(type)]
      },
    # greater than
    IL::BinaryOp.new(IL::BinaryOp::Operator::GT,
                     Pattern::ValueWildcard.new,
                     Pattern::ValueWildcard.new) =>
      -> (t, o) {
        left = t.transform(o.left)
        right = t.transform(o.right)

        il_type = t.get_il_type(o.left)

        # choose between gt_s, gt_u, and gt
        gt = nil
        if il_type.signed?
          type = Instructions::to_integer_type(il_type)
          gt = Instructions::GreaterThanSigned.new(type)
        elsif il_type.unsigned?
          type = Instructions::to_integer_type(il_type)
          gt = Instructions::GreaterThanUnsigned.new(type)
        elsif il_type.float?
          type = Instructions::to_float_type(il_type)
          gt = Instructions::GreaterThan.new(type)
        end

        [left, right, gt]
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
        if il_type.signed?
          type = Instructions::to_integer_type(il_type)
          lt = Instructions::LessThanSigned.new(type)
        elsif il_type.unsigned?
          type = Instructions::to_integer_type(il_type)
          lt = Instructions::LessThanUnsigned.new(type)
        elsif il_type.float?
          type = Instructions::to_float_type(il_type)
          lt = Instructions::LessThan.new(type)
        end

        instructions = []
        instructions.concat(left)
        instructions.concat(right)
        instructions.push(lt)

        instructions
      },
    # greater than equal
    IL::BinaryOp.new(IL::BinaryOp::Operator::GEQ,
                     Pattern::ValueWildcard.new,
                     Pattern::ValueWildcard.new) =>
      -> (t, o) {
        left = t.transform(o.left)
        right = t.transform(o.right)

        il_type = t.get_il_type(o.left)

        # choose between ge_s, ge_u, and ge
        ge = nil
        if il_type.signed?
          type = Instructions::to_integer_type(il_type)
          ge = Instructions::GreaterOrEqualSigned.new(type)
        elsif il_type.unsigned?
          type = Instructions::to_integer_type(il_type)
          ge = Instructions::GreaterOrEqualUnsigned.new(type)
        elsif il_type.float?
          type = Instructions::to_float_type(il_type)
          ge = Instructions::GreaterOrEqual.new(type)
        end

        [left, right, ge]
      },
    # less than equal
    IL::BinaryOp.new(IL::BinaryOp::Operator::LEQ,
                     Pattern::ValueWildcard.new,
                     Pattern::ValueWildcard.new) =>
      -> (t, o) {
        left = t.transform(o.left)
        right = t.transform(o.right)

        il_type = t.get_il_type(o.left)

        # choose between le_s, le_u, and le
        le = nil
        if il_type.signed?
          type = Instructions::to_integer_type(il_type)
          le = Instructions::LessOrEqualSigned.new(type)
        elsif il_type.unsigned?
          type = Instructions::to_integer_type(il_type)
          le = Instructions::LessOrEqualUnsigned.new(type)
        elsif il_type.float?
          type = Instructions::to_float_type(il_type)
          le = Instructions::LessOrEqual.new(type)
        end

        [left, right, le]
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

        instructions = []
        instructions.concat(value)
        instructions.push(Instructions::Return.new)

        instructions
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
