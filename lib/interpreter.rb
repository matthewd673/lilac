# typed: strict
# NOTE: sorbet doesn't support refinements which are used in Interpreter
require "sorbet-runtime"
require_relative "il"
require_relative "visitor"

module Interpreter
  extend T::Sig
  include Kernel

  class InterpreterValue
    extend T::Sig

    sig { returns(IL::Type) }
    attr_reader :type
    sig { returns(T.untyped) }
    attr_reader :value

    sig { params(type: IL::Type, value: T.untyped).void }
    def initialize(type, value)
      @type = type
      @value = value
    end
  end

  class SymbolInfo
    extend T::Sig

    sig { returns(String) }
    attr_reader :name
    sig { returns(IL::Type) }
    attr_reader :type
    sig { returns T.untyped }
    attr_accessor :value

    sig { params(name: String, type: IL::Type, value: T.untyped).void }
    def initialize(name, type, value)
      @name = name
      @type = type
      @value = value
    end
  end

  class Context
    extend T::Sig

    sig { returns(Integer) }
    attr_accessor :ip
    sig { returns(T::Hash[String, SymbolInfo]) }
    attr_reader :symbols # symbol name -> SymbolInfo
    sig { returns(T::Hash[String, Integer]) }
    attr_reader :label_indices # label name -> index in stmt_list

    sig { void }
    def initialize
      @ip = T.let(0, Integer)
      @symbols = T.let(Hash.new, T::Hash[String, SymbolInfo])
      @label_indices = T.let(Hash.new, T::Hash[String, Integer])
    end
  end

  sig { params(program: IL::Program).void }
  def self.interpret(program)
    context = Context.new
    visitor = Visitor.new(VISIT_LAMBDAS)

    # collect all stmts in the program
    stmts = []
    program.each_stmt { |s|
      stmts.push(s)
    }

    # register labels
    stmts.each_with_index { |s, i|
      if s.is_a?(IL::Label)
        # check for duplicate labels
        if context.label_indices.include?(s.name)
          raise("Multiple definitions of label #{s.name}")
        end

        context.label_indices[s.name] = i
      end
    }

    # interpret
    stmt_ct = 0
    while context.ip < stmts.length
      s = stmts[context.ip]
      # s.interpret(context)
      visitor.visit([s, context])
      context.ip += 1
      stmt_ct += 1
    end

    puts("---")
    puts("Interpretation complete")
    puts("Statements executed: #{stmt_ct}")

    # TODO: temp sanity check
    puts("Symbol table state:")
    context.symbols.keys.each { |k|
      info = context.symbols[k]
      if not info then next end # skip nil info (should never happen)
      puts("#{k} = #{info.value} (#{info.type})")
    }
  end

  protected

  VISIT_VALUE = T.let(-> (v, o) {
   if self.class == IL::Value
     raise("#{self.class} is a stub and should not be constructed")
   else
     raise("Interpretation of #{self.class} is not implemented")
   end
  }, Visitor::Lambda)

  VISIT_CONSTANT = T.let(-> (v, o) {
    type = o[0].type
    value = o[0].value
    return InterpreterValue.new(type, value)
  }, Visitor::Lambda)

  VISIT_ID = T.let(-> (v, o) {
    context = o[1]
    name = o[0].name

    if not context.symbols.include?(name)
      raise("Undefined ID #{name}")
    end

    info = context.symbols[name]
    if not info # required by by sorbet for below usage
      raise("ID #{name} is defined but has NIL SymbolInfo")
    end
    return InterpreterValue.new(info.type, info.value)
  }, Visitor::Lambda)

  VISIT_EXPRESSION = T.let(-> (v, o) {
    if self.class == IL::Expression
      raise("#{self.class} is a stub and should not be constructed")
    else
      raise("Interpretation of #{self.class} is not implemented")
    end
  }, Visitor::Lambda)

  VISIT_BINARYOP = T.let(-> (v, o) {
    context = o[1]
    left = o[0].left
    right = o[0].right
    op = o[0].op

    left = v.visit([left, context])
    right = v.visit([right, context])

    if not left.type.eql?(right.type)
      raise("Mismatched types '#{left.type}' and '#{right.type}'")
    end

    result = case op
    when IL::BinaryOp::ADD_OP
      left.value + right.value
    when IL::BinaryOp::SUB_OP
      left.value - right.value
    when IL::BinaryOp::MUL_OP
      left.value * right.value
    when IL::BinaryOp::DIV_OP
      left.value / right.value
    when IL::BinaryOp::EQ_OP
      if left.value == right.value then 1 else 0 end
    when IL::BinaryOp::LT_OP
      if left.value < right.value then 1 else 0 end
    when IL::BinaryOp::GT_OP
      if left.value > right.value then 1 else 0 end
    when IL::BinaryOp::LEQ_OP
      if left.value <= right.value then 1 else 0 end
    when IL::BinaryOp::GEQ_OP
      if left.value >= right.value then 1 else 0 end
    when IL::BinaryOp::OR_OP
      if left.value != 0 || right.value != 0 then 1 else 0 end
    when IL::BinaryOp::AND_OP
      if left.value != 0 && right.value != 0 then 1 else 0 end
    else
      raise("Invalid binary operator '#{op}'")
    end

    # since both operands must have same type we can return either as our type
    return InterpreterValue.new(left.type, result)
  }, Visitor::Lambda)

  VISIT_UNARYOP = T.let(-> (v, o) {
    context = o[1]
    value = o[0].value
    op = o[0].op

    value = v.visit([value, context])

    result = case op
    when IL::UnaryOp::NEG_OP
      0 - value.value
    when IL::UnaryOp::POS_OP
      value.value # does nothing
    else
      raise("Invalid unary operator '#{op}'")
    end

    return InterpreterValue.new(value.type, result)
  }, Visitor::Lambda)

  VISIT_STATEMENT = T.let(-> (v, o) {
    if self.class == IL::Statement
      raise("#{self.class} is a stub and should not be constructed")
    else
      raise("Interpretation of #{self.class} is not implemented")
    end
  }, Visitor::Lambda)

  VISIT_DECLARATION = T.let(-> (v, o) {
    context = o[1]
    type = o[0].type
    id = o[0].id
    rhs = o[0].rhs

    # check for redeclaration
    if context.symbols.include?(id.name)
      raise("Redeclaration of ID '#{id.name}'")
    end
    # insert id in symbol table with appropriate type
    rhs_eval = v.visit([rhs, context])

    # catch type mismatch
    if not rhs_eval.type.eql?(type)
      raise("Cannot declare ID of type #{type} with value of type #{rhs_eval.type}")
    end

    context.symbols[id.name] = Interpreter::SymbolInfo.new(id.name,
                                                           type,
                                                           rhs_eval.value)
  }, Visitor::Lambda)

  VISIT_ASSIGNMENT = T.let(-> (v, o) {
    context = o[1]
    id = o[0].id
    rhs = o[0].rhs

    # make sure variable has been declared
    if not context.symbols.include?(id.name)
      raise("Assigning to undefined ID '#{id.name}'")
    end

    # update value in symbol table
    rhs_eval = v.visit([rhs, context])

    # catch type mismatch
    info = context.symbols[id.name]
    if not info # required by sorbet for below usage
      raise("ID #{o.name} is defined but has NIL SymbolInfo")
    end
    if not rhs_eval.type.eql?(info.type)
      raise("Cannot assign value of type #{rhs_eval.type} into #{id.name} (type #{info.type})")
    end

    info.value = rhs_eval.value
  }, Visitor::Lambda)

  VISIT_LABEL = T.let(-> (v, o) {
    # empty
  }, Visitor::Lambda)

  VISIT_JUMP = T.let(-> (v, o) {
    context = o[1]
    target = o[0].target

    # check for invalid target
    if not context.label_indices.include?(target)
      raise("Invalid jump target '#{target}'")
    end

    # move instruction pointer there
    index = context.label_indices[target]
    if not index
      raise("Label #{target} is defined but has NIL instruction index")
    end
    context.ip = index
  }, Visitor::Lambda)

  VISIT_JUMPZERO = T.let(-> (v, o) {
    context = o[1]
    cond = o[0].cond
    target = o[0].target

    # evaluate conditional
    cond_eval = v.visit([cond, context])

    # check for invalid target
    if not context.label_indices.include?(target)
      raise("Invalid jump target '#{target}'")
    end

    # move instruction pointer there if zero
    if cond_eval.value == 0
      index = context.label_indices[target]
      if not index
        raise("Label #{target} is defined but has NIL instruction index")
      end
      context.ip = index
    end
  }, Visitor::Lambda)

  VISIT_JUMPNOTZERO = T.let(-> (v, o) {
    context = o[1]
    cond = o[0].cond
    target = o[0].target

    # evaluate conditional
    cond_eval = v.visit([cond, context])

    # check for invalid target
    if not context.label_indices.include?(target)
      raise("Invalid jump target '#{target}'")
    end

    # move instruction pointer there if not zero
    if cond_eval.value != 0
      index = context.label_indices[target]
      if not index
        raise("Label #{target} is defined but has NIL instruction index")
      end
      context.ip = index
    end
  }, Visitor::Lambda)

  VISIT_LAMBDAS = T.let({
    IL::Value => VISIT_VALUE,
    IL::Constant => VISIT_CONSTANT,
    IL::ID => VISIT_ID,
    IL::Expression => VISIT_EXPRESSION,
    IL::BinaryOp => VISIT_BINARYOP,
    IL::UnaryOp => VISIT_UNARYOP,
    IL::Statement => VISIT_STATEMENT,
    IL::Declaration => VISIT_DECLARATION,
    IL::Assignment => VISIT_ASSIGNMENT,
    IL::Label => VISIT_LABEL,
    IL::Jump => VISIT_JUMP,
    IL::JumpZero => VISIT_JUMPZERO,
    IL::JumpNotZero => VISIT_JUMPNOTZERO,
  }, Visitor::LambdaHash)
end
