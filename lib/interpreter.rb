# typed: strict
# frozen_string_literal: true

require "sorbet-runtime"
require_relative "il"
require_relative "visitor"
require_relative "validation/validation_runner"
require_relative "analysis/bb"
require_relative "analysis/cfg"

module Lilac
  # The Interpreter module provides a simple interpreter for the Lilac IL.
  # Lilac IL is not designed to be an interpreted language (and does
  # not support any dynamic features that may be expected of an interpreted
  # language). The interpreter is only provided as an easy way to execute
  # Lilac IL without translating it to a machine-dependent form.
  module Interpreter
    extend T::Sig
    include Kernel

    sig { params(program: IL::CFGProgram, validate: T::Boolean).void }
    # Interpret a program.
    #
    # @param [IL::CFGProgram] program The program to interpret.
    def self.interpret(program, validate: true)
      context = Context.new(program.cfg.entry)
      visitor = Visitor.new(VISIT_LAMBDAS)

      # run all validations before interpreting
      # TODO: update to work with CFG (or move all validations to tests)
      # if validate
      # validation_runner = Validation::ValidationRunner.new(program)
      # validation_runner.run_passes(Validation::VALIDATIONS)
      # end

      # collect all funcs in the program
      context.funcs = {}
      program.each_func do |f|
        context.funcs[f.name] = f
      end

      # collect all labels in program -- including within functions
      context.label_blocks = {}
      register_labels(context.label_blocks, program.cfg)
      program.each_func do |f|
        register_labels(context.label_blocks, f.cfg)
      end

      # begin interpretation
      interpret_cfg(program.cfg, visitor, context)

      puts("---")
      puts("Interpretation complete")

      # NOTE: temp sanity check
      puts("Symbol table state:")
      puts(context.symbols.to_s)
    end

    protected

    sig do
      params(label_hash: T::Hash[String, Analysis::BB], cfg: Analysis::CFG).void
    end
    def self.register_labels(label_hash, cfg)
      cfg.each_node do |b|
        if b.entry
          label_hash[T.unsafe(b.entry).name] = b
        end
      end
    end

    sig do
      params(cfg: Analysis::CFG, visitor: Visitor, context: Context)
        .returns(T.nilable(InterpreterValue))
    end
    def self.interpret_cfg(cfg, visitor, context)
      while context.current != cfg.exit
        # interpret the current block
        context.current.stmt_list.each do |s|
          # special handling for return
          if s.is_a?(IL::Return)
            ret_result = visitor.visit(s.value, ctx: context)
            context.step_ct += 1
            return ret_result
          end

          # visit a statement normally
          visitor.visit(s, ctx: context)
          context.step_ct += 1
        end

        # once we've reached the end of the current block we must either:
        # jump (perhaps conditionally) or move to the block's (single) successor
        # block exits with a conditional jump
        if context.current.exit && context.current.exit.class != IL::Jump
          jump = context.current.exit
          # evaluate conditional and then jump
          cond_result = visitor.visit(jump, ctx: context)
          context.step_ct += 1
          # take appropriate branch
          cfg.each_outgoing(context.current) do |o|
            if o.to.true_branch != cond_result
              next
            end

            context.current = o.to
            break
          end
        # block either exits with a jmp or has no @exit
        else
          cfg.each_successor(context.current) do |s|
            context.current = s
            break # just take the first successor (there should only be one)
          end
        end
      end

      # no return statement hit
      # should only happen at top level in valid IL
      nil
    end

    VISIT_VALUE = T.let(lambda { |v, o, context|
      if instance_of?(IL::Value)
        raise "#{self.class} is a stub and should not be constructed"
      end

      raise "Interpretation of #{self.class} is not implemented"
    }, Visitor::Lambda)

    VISIT_CONSTANT = T.let(lambda { |v, o, context|
      type = o.type
      value = o.value
      InterpreterValue.new(type, value)
    }, Visitor::Lambda)

    VISIT_ID = T.let(lambda { |v, o, context|
      key = o.key

      info = context.symbols.lookup(key)

      InterpreterValue.new(info.type, info.value)
    }, Visitor::Lambda)

    VISIT_EXPRESSION = T.let(lambda { |v, o, context|
      if instance_of?(IL::Expression)
        raise "#{self.class} is a stub and should not be constructed"
      end

      raise "Interpretation of #{self.class} is not implemented"
    }, Visitor::Lambda)

    VISIT_BINARYOP = T.let(lambda { |v, o, context|
      left = o.left
      right = o.right
      op = o.op

      left = v.visit(left, ctx: context)
      right = v.visit(right, ctx: context)

      unless left.type.eql?(right.type)
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
                 left.value == right.value ? 1 : 0
               when IL::BinaryOp::Operator::NEQ
                 left.value != right.value ? 1 : 0
               when IL::BinaryOp::Operator::LT
                 left.value < right.value ? 1 : 0
               when IL::BinaryOp::Operator::GT
                 left.value > right.value ? 1 : 0
               when IL::BinaryOp::Operator::LEQ
                 left.value <= right.value ? 1 : 0
               when IL::BinaryOp::Operator::GEQ
                 left.value >= right.value ? 1 : 0
               when IL::BinaryOp::Operator::OR
                 left.value != 0 || right.value != 0 ? 1 : 0
               when IL::BinaryOp::Operator::AND
                 left.value != 0 && right.value != 0 ? 1 : 0
               else # cannot use T.absurd since o.op is untyped
                 raise("Unimplemented binary operator '#{op}'")
               end

      # since both operands must have same type we can return either as our type
      InterpreterValue.new(left.type, result)
    }, Visitor::Lambda)

    VISIT_UNARYOP = T.let(lambda { |v, o, context|
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

      InterpreterValue.new(value.type, result)
    }, Visitor::Lambda)

    VISIT_CALL = T.let(lambda { |v, o, context|
      func_name = o.func_name
      args = o.args
      func = context.funcs[func_name]
      cfg = func.cfg

      # fill in param values with call args
      arg_vals = []
      args.each do |a|
        arg_vals.push(v.visit(a, ctx: context).value)
      end

      # temporarily leave current func scope
      this_func_scope = nil
      if context.in_func
        this_func_scope = context.symbols.pop_scope
      end
      this_current = context.current

      # enter new scope for function
      context.symbols.push_scope(Scope.new)
      context.in_func = func
      context.current = func.cfg.entry

      # fill in params with args (that were computed in this_func_scope)
      arg_index = 0
      func.params.each do |p|
        arg_symbol = SymbolInfo.new(p.id.key, p.type, arg_vals[arg_index])
        context.symbols.insert(arg_symbol)
        arg_index += 1
      end

      # interpret body of function
      ret_value = interpret_cfg(cfg, v, context)

      # re-enter current func scope
      context.symbols.pop_scope
      if this_func_scope
        context.symbols.push_scope(this_func_scope)
      end
      context.current = this_current

      # return value from inside function
      ret_value
    }, Visitor::Lambda)

    VISIT_PHI = T.let(lambda { |v, o, context|
      ids = o.ids

      # find the id in the phi function that was last written to
      last_written = T.let(nil, T.nilable(SymbolInfo))
      ids.each do |id|
        id_info = context.symbols.lookup(id.key)

        # can happen if other branch has never been hit so far
        unless id_info
          next
        end

        unless last_written
          last_written = id_info
          next
        end

        if id_info.write_time > last_written.write_time
          last_written = id_info
        end
      end

      unless last_written
        raise "Failed to lookup value for phi function"
      end

      InterpreterValue.new(last_written.type, last_written.value)
    }, Visitor::Lambda)

    VISIT_STATEMENT = T.let(lambda { |v, o, context|
      if instance_of?(IL::Statement)
        raise "#{self.class} is a stub and should not be constructed"
      end

      raise "Interpretation of #{self.class} is not implemented"
    }, Visitor::Lambda)

    VISIT_DEFINITION = T.let(lambda { |v, o, context|
      type = o.type
      id = o.id
      rhs = o.rhs

      # insert id in symbol table with appropriate type
      rhs_eval = v.visit(rhs, ctx: context)

      symbol = SymbolInfo.new(id.key, type, rhs_eval.value)
      symbol.write_time = context.step_ct # note write time
      context.symbols.insert(symbol)
    }, Visitor::Lambda)

    VISIT_JUMP = T.let(lambda { |v, o, context|
      target = o.target

      # move instruction pointer there
      index = context.label_indices[target]
      context.ip = index
    }, Visitor::Lambda)

    VISIT_JUMPZERO = T.let(lambda { |v, o, context|
      cond = o.cond

      # evaluate conditional
      cond_eval = v.visit(cond, ctx: context)

      # return true if jump should execute
      cond_eval.value == 0
    }, Visitor::Lambda)

    VISIT_JUMPNOTZERO = T.let(lambda { |v, o, context|
      cond = o.cond

      # evaluate conditional
      cond_eval = v.visit(cond, ctx: context)

      # return true if jump should execute
      cond_eval.value != 0
    }, Visitor::Lambda)

    VISIT_LAMBDAS = T.let({
      IL::Value => VISIT_VALUE,
      IL::Constant => VISIT_CONSTANT,
      IL::ID => VISIT_ID,
      IL::Expression => VISIT_EXPRESSION,
      IL::BinaryOp => VISIT_BINARYOP,
      IL::UnaryOp => VISIT_UNARYOP,
      IL::Call => VISIT_CALL,
      IL::Phi => VISIT_PHI,
      IL::Statement => VISIT_STATEMENT,
      IL::Definition => VISIT_DEFINITION,
      IL::Jump => VISIT_JUMP,
      IL::JumpZero => VISIT_JUMPZERO,
      IL::JumpNotZero => VISIT_JUMPNOTZERO,
      # NOTE: IL::Return is handled manually as a special case
    }.freeze, Visitor::LambdaHash)

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

      sig { returns(T.untyped) }
      attr_accessor :value

      sig { returns(Integer) }
      attr_accessor :write_time

      sig { params(key: String, type: IL::Type, value: T.untyped).void }
      def initialize(key, type, value)
        @key = key
        @type = type
        @value = value
        @write_time = T.let(0, Integer)
      end

      sig { returns(String) }
      def to_s
        "#{@key}: #{@value}"
      end
    end

    # A scope contains symbols. NOTE: Adapted from symbol_table.rb
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
        symbol = @symbols[key]

        # FIXME: patch for weird SSA Register renaming
        #        REMOVE once to_ssa renaming is fixed!
        if !symbol && !key.include?("#")
          symbol = @symbols["#{key}#0"]
        end

        symbol
      end

      sig { returns(String) }
      def to_s
        s = ""
        @symbols.each_key do |k|
          s += "#{@symbols[k]}\n"
        end
        s.chomp!("\n")
        s
      end
    end

    # A symbol table stores symbol information.
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
        @scopes.reverse_each do |s|
          symbol = s.lookup(key)
          if symbol then return symbol end
        end
        nil
      end

      sig { returns(String) }
      def to_s
        s = ""
        @scopes.each do |scope|
          s += "scope:\n"
          s += scope.to_s
        end
        s
      end
    end

    # A Context contains all of the information that the interpreter may
    # need during a step of interpretation including a symbol table,
    # instruction pointer, and etc.
    class Context
      extend T::Sig

      sig { returns(Analysis::BB) }
      attr_accessor :current

      sig { returns(Integer) }
      attr_accessor :step_ct

      sig { returns(SymbolTable) }
      attr_reader :symbols

      sig { returns(T::Hash[String, IL::CFGFuncDef]) }
      attr_accessor :funcs # func name -> CFGFuncDef

      sig { returns(T.nilable(IL::CFGFuncDef)) }
      attr_accessor :in_func

      sig { returns(T::Hash[String, Analysis::BB]) }
      attr_accessor :label_blocks # label name -> BB object

      sig { params(entrypoint: Analysis::BB).void }
      def initialize(entrypoint)
        @current = entrypoint
        @step_ct = T.let(0, Integer)
        @symbols = T.let(SymbolTable.new, SymbolTable)
        @symbols.push_scope(Scope.new) # symbol table always has top-level scope
        @funcs = T.let({}, T::Hash[String, IL::CFGFuncDef])
        @in_func = T.let(nil, T.nilable(IL::CFGFuncDef))
        @label_blocks = T.let({}, T::Hash[String, Analysis::BB])
      end
    end
  end
end
