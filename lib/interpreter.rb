# typed: strict
require "sorbet-runtime"
require_relative "il"
require_relative "visitor"
require_relative "validation/validation_runner"

# The Interpreter module provides a simple interpreter for the Lilac IL.
# Lilac IL is not designed to be an interpreted language (and does
# not support any dynamic features that may be expected of an interpreted
# language). The interpreter is only provided as an easy way to execute
# Lilac IL without translating it to a machine-dependent form.
module Interpreter
  extend T::Sig
  include Kernel

  sig { params(program: IL::Program, validate: T::Boolean).void }
  # Interpret a program.
  #
  # @param [IL::Program] program The program to interpret.
  def self.interpret(program, validate: true)
    context = Context.new
    visitor = Visitor.new(VISIT_LAMBDAS)

    # run all validations before interpreting
    if validate
      validation_runner = Validation::ValidationRunner.new(program)
      validation_runner.run_passes(Validation::VALIDATIONS)
    end

    # collect all funcs in the program
    funcs = {} # [String] name -> [IL::FuncDef] func def object
    program.item_list.each { |i|
      if not i.is_a?(IL::FuncDef) then next end

      funcs[i.name] = i
    }
    context.funcs = funcs

    # collect all labels in program -- including within functions
    context.label_indices = register_labels(program.item_list)

    # begin interpretation
    interpret_items(program.item_list, visitor, context)

    puts("---")
    puts("Interpretation complete")

    # NOTE: temp sanity check
    puts("Symbol table state:")
    puts(context.symbols.to_s)
  end

  protected

  sig { params(item_list: T::Array[IL::TopLevelItem])
          .returns(T::Hash[String, Integer]) }
  def self.register_labels(item_list)
    index = 0
    label_map = Hash.new

    item_list.each { |i|
      # recurse on funcdefs
      if i.is_a?(IL::FuncDef)
        inner = register_labels(i.stmt_list)
        # add the labels that it found into the main list
        inner.keys.each { |k|
          label_map[k] = inner[k]
        }

        index += 1
        next
      end

      # register labels in item list
      if not i.is_a?(IL::Label) then next end
      label_map[i.name] = index
      index += 1
    }

    return label_map
  end

  sig { params(item_list: T::Array[IL::TopLevelItem],
               visitor: Visitor,
               context: Context).returns(T.nilable(InterpreterValue)) }
  def self.interpret_items(item_list, visitor, context)
    while context.ip < item_list.length
      i = item_list[context.ip]

      # skip items that do nothing
      if i.is_a?(IL::FuncDef) or i.is_a?(IL::Label)
        context.ip += 1
        next
      end

      # special handling for Return
      if i.is_a?(IL::Return)
        return visitor.visit(i.value, ctx: context)
      end

      # visit a statement normally
      visitor.visit(i, ctx: context)
      context.ip += 1
    end

    # if no return statement, return nil
    # this should only happen at top-level in valid IL
    return nil
  end

  VISIT_VALUE = T.let(-> (v, o, context) {
   if self.class == IL::Value
     raise("#{self.class} is a stub and should not be constructed")
   else
     raise("Interpretation of #{self.class} is not implemented")
   end
  }, Visitor::Lambda)

  VISIT_CONSTANT = T.let(-> (v, o, context) {
    type = o.type
    value = o.value
    return InterpreterValue.new(type, value)
  }, Visitor::Lambda)

  VISIT_ID = T.let(-> (v, o, context) {
    key = o.key

    info = context.symbols.lookup(key)
    return InterpreterValue.new(info.type, info.value)
  }, Visitor::Lambda)

  VISIT_EXPRESSION = T.let(-> (v, o, context) {
    if self.class == IL::Expression
      raise("#{self.class} is a stub and should not be constructed")
    else
      raise("Interpretation of #{self.class} is not implemented")
    end
  }, Visitor::Lambda)

  VISIT_BINARYOP = T.let(-> (v, o, context) {
    left = o.left
    right = o.right
    op = o.op

    left = v.visit(left, ctx: context)
    right = v.visit(right, ctx: context)

    if not left.type.eql?(right.type)
      raise("Mismatched types '#{left.type}' and '#{right.type}'")
    end

    # cannot use BinaryOp.calculate since these are InterpreterValues
    result = case op
    when IL::BinaryOp::Operator::ADD
      left.value + right.value
    when IL::BinaryOp::Operator::SUB
      left.value - right.value
    when IL::BinaryOp::Operator::MUL
      left.value * right.value
    when IL::BinaryOp::Operator::DIV
      left.value / right.value
    when IL::BinaryOp::Operator::EQ
      if left.value == right.value then 1 else 0 end
    when IL::BinaryOp::Operator::NEQ
      if left.value != right.value then 1 else 0 end
    when IL::BinaryOp::Operator::LT
      if left.value < right.value then 1 else 0 end
    when IL::BinaryOp::Operator::GT
      if left.value > right.value then 1 else 0 end
    when IL::BinaryOp::Operator::LEQ
      if left.value <= right.value then 1 else 0 end
    when IL::BinaryOp::Operator::GEQ
      if left.value >= right.value then 1 else 0 end
    when IL::BinaryOp::Operator::OR
      if left.value != 0 || right.value != 0 then 1 else 0 end
    when IL::BinaryOp::Operator::AND
      if left.value != 0 && right.value != 0 then 1 else 0 end
    else # cannot use T.absurd since o.op is untyped
      raise("Unimplemented binary operator '#{op}'")
    end

    # since both operands must have same type we can return either as our type
    return InterpreterValue.new(left.type, result)
  }, Visitor::Lambda)

  VISIT_UNARYOP = T.let(-> (v, o, context) {
    value = o.value
    op = o.op

    value = v.visit(value, ctx: context)

    # cannot use UnaryOp.calculate since these are InterpreterValues
    result = case op
    when IL::UnaryOp::Operator::NEG
      0 - value.value
    else
      raise("Unsupported unary operator '#{op}'")
    end

    return InterpreterValue.new(value.type, result)
  }, Visitor::Lambda)

  VISIT_CALL = T.let(-> (v, o, context) {
    func_name = o.func_name
    args = o.args
    func = context.funcs[func_name]
    stmt_list = func.stmt_list

    # fill in param values with call args
    arg_vals = []
    args.each { |a|
      arg_vals.push(v.visit(a, ctx: context).value)
    }

    # temporarily leave current func scope
    this_func_scope = nil
    if context.in_func
      this_func_scope = context.symbols.pop_scope
    end
    this_ip = context.ip

    # enter new scope for function
    context.symbols.push_scope(Scope.new)
    context.in_func = func
    context.ip = 0

    # fill in params with args (that were computed in this_func_scope)
    arg_index = 0
    func.params.each { |p|
      arg_symbol = SymbolInfo.new(p.id.key, p.type, arg_vals[arg_index])
      context.symbols.insert(arg_symbol)
      arg_index += 1
    }

    # interpret body of function
    ret_value = interpret_items(stmt_list, v, context)

    # re-enter current func scope
    context.symbols.pop_scope
    if this_func_scope
      context.symbols.push_scope(this_func_scope)
    end
    context.ip = this_ip

    # return value from inside function
    return ret_value
  }, Visitor::Lambda)

  VISIT_STATEMENT = T.let(-> (v, o, context) {
    if self.class == IL::Statement
      raise("#{self.class} is a stub and should not be constructed")
    else
      raise("Interpretation of #{self.class} is not implemented")
    end
  }, Visitor::Lambda)

  VISIT_DEFINITION = T.let(-> (v, o, context) {
    type = o.type
    id = o.id
    rhs = o.rhs

    # insert id in symbol table with appropriate type
    rhs_eval = v.visit(rhs, ctx: context)

    symbol = SymbolInfo.new(id.key, type, rhs_eval.value)
    context.symbols.insert(symbol)
  }, Visitor::Lambda)

  VISIT_JUMP = T.let(-> (v, o, context) {
    target = o.target

    # move instruction pointer there
    index = context.label_indices[target]
    context.ip = index
  }, Visitor::Lambda)

  VISIT_JUMPZERO = T.let(-> (v, o, context) {
    cond = o.cond
    target = o.target

    # evaluate conditional
    cond_eval = v.visit(cond, ctx: context)

    # move instruction pointer there if zero
    if cond_eval.value == 0
      index = context.label_indices[target]
      context.ip = index
    end
  }, Visitor::Lambda)

  VISIT_JUMPNOTZERO = T.let(-> (v, o, context) {
    cond = o[0].cond
    target = o[0].target

    # evaluate conditional
    cond_eval = v.visit(cond, ctx: context)

    # move instruction pointer there if not zero
    if cond_eval.value != 0
      index = context.label_indices[target]
      context.ip = index
    end
  }, Visitor::Lambda)

  VISIT_RETURN = T.let(-> (v, o, context) {
    # TODO
    puts("TODO: implement Return")
  }, Visitor::Lambda)

  VISIT_LAMBDAS = T.let({
    IL::Value => VISIT_VALUE,
    IL::Constant => VISIT_CONSTANT,
    IL::ID => VISIT_ID,
    IL::Expression => VISIT_EXPRESSION,
    IL::BinaryOp => VISIT_BINARYOP,
    IL::UnaryOp => VISIT_UNARYOP,
    IL::Call => VISIT_CALL,
    IL::Statement => VISIT_STATEMENT,
    IL::Definition => VISIT_DEFINITION,
    IL::Jump => VISIT_JUMP,
    IL::JumpZero => VISIT_JUMPZERO,
    IL::JumpNotZero => VISIT_JUMPNOTZERO,
    IL::Return => VISIT_RETURN,
  }, Visitor::LambdaHash)

  private

  # An InterpreterValue is a value that can be returned while evaluating
  # an expression. It abstracts away details about the source of the value
  # (like if its a Constant or came from the symbol table).
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

    sig { returns(String) }
    def to_s
      "#{@type} #{@value}"
    end
  end

  # The SymbolInfo class contains information about variables in the
  # interpreter's memory including their name, type, and current value.
  class SymbolInfo
    extend T::Sig

    sig { returns(String) }
    attr_reader :key
    sig { returns(IL::Type) }
    attr_reader :type
    sig { returns T.untyped }
    attr_accessor :value

    sig { params(key: String, type: IL::Type, value: T.untyped).void }
    def initialize(key, type, value)
      @key = key
      @type = type
      @value = value
    end

    sig { returns(String) }
    def to_s
      "#{@key}: #{@value}"
    end
  end

  # NOTE: Adapted from symbol_table.rb
  class Scope
    extend T::Sig

    sig { void }
    def initialize
      @symbols = T.let({}, T::Hash[String, SymbolInfo])
    end

    sig { params(symbol: SymbolInfo).void }
    def insert(symbol)
      @symbols[symbol.key] = symbol
    end

    sig { params(key: String).returns(T.nilable(SymbolInfo)) }
    def lookup(key)
      @symbols[key]
    end

    sig { returns(String) }
    def to_s
      s = ""
      @symbols.keys.each { |k|
        s += "#{@symbols[k]}\n"
      }
      s.chomp!("\n")
      return s
    end
  end

  # NOTE: Adapted from symbol_table.rb
  class SymbolTable
    extend T::Sig

    sig { void }
    def initialize
      @scopes = T.let([], T::Array[Scope])
    end

    sig { params(scope: Scope).void }
    def push_scope(scope)
      @scopes.push(scope)
    end

    sig { returns(T.nilable(Scope)) }
    def pop_scope
      @scopes.pop
    end

    sig { params(symbol: SymbolInfo).void }
    def insert(symbol)
      T.unsafe(@scopes[-1]).insert(symbol)
    end

    sig { params(key: String).returns(T.nilable(SymbolInfo)) }
    def lookup(key)
      @scopes.reverse_each { |s|
        symbol = s.lookup(key)
        if symbol then return symbol end
      }
      return nil
    end

    sig { returns(String) }
    def to_s
      s = ""
      @scopes.each { |scope|
        s += "scope:\n"
        s += scope.to_s
      }
      return s
    end
  end

  # A Context contains all of the information that the interpreter may
  # need during a step of interpretation including a symbol table,
  # instruction pointer, and etc.
  class Context
    extend T::Sig

    sig { returns(Integer) }
    attr_accessor :ip
    sig { returns(SymbolTable) }
    attr_reader :symbols
    sig { returns(T::Hash[String, IL::FuncDef]) }
    attr_accessor :funcs # func name -> FuncDef
    sig { returns(T.nilable(IL::FuncDef)) }
    attr_accessor :in_func
    sig { returns(T::Hash[String, Integer]) }
    attr_accessor :label_indices # label name -> index in stmt_list

    sig { void }
    def initialize
      @ip = T.let(0, Integer)
      @symbols = T.let(SymbolTable.new, SymbolTable)
      @symbols.push_scope(Scope.new) # symbol table always has top-level scope
      @funcs = T.let(Hash.new, T::Hash[String, IL::FuncDef])
      @in_func = T.let(nil, T.nilable(IL::FuncDef))
      @label_indices = T.let(Hash.new, T::Hash[String, Integer])
    end
  end
end
