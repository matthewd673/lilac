# typed: true
# NOTE: sorbet doesn't support refinements which are used in Interpreter
require "sorbet-runtime"
require_relative "il"

module Interpreter
  extend T::Sig
  include Kernel

  class Value
    extend T::Sig

    sig { returns(String) }
    attr_reader :type
    sig { returns(T.untyped) }
    attr_reader :value

    sig { params(type: String, value: T.untyped).void }
    def initialize(type, value)
      @type = type
      @value = value
    end
  end

  class SymbolInfo
    extend T::Sig

    sig { returns(String) }
    attr_reader :name
    sig { returns(String) }
    attr_reader :type
    sig { returns T.untyped }
    attr_accessor :value

    sig { params(name: String, type: String, value: T.untyped).void }
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
      s.interpret(context)
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

  refine IL::Value do
    extend T::Sig

    sig { params(context: Interpreter::Context).returns(Interpreter::Value) }
    def evaluate(context)
      if self.class == IL::Value
        raise("#{self.class} is a stub and should not be constructed")
      else
        raise("Interpretation of #{self.class} is not implemented")
      end
    end
  end

  refine IL::Constant do
    extend T::Sig

    def evaluate(context)
      return Interpreter::Value.new(@type, @value)
    end
  end

  refine IL::ID do
    extend T::Sig

    def evaluate(context)
      if not context.symbols.include?(@name)
        raise("Undefined ID #{@name}")
      end

      info = context.symbols[@name]
      if not info # required by by sorbet for below usage
        raise("ID #{@name} is defined but has NIL SymbolInfo")
      end
      return Interpreter::Value.new(info.type, info.value)
    end
  end

  refine IL::Expression do
    extend T::Sig

    sig { params(context: Interpreter::Context).returns(Interpreter::Value) }
    def evaluate(context)
      if self.class == IL::Expression
        raise("#{self.class} is a stub and should not be constructed")
      else
        raise("Interpretation of #{self.class} is not implemented")
      end
    end
  end

  refine IL::BinaryOp do
    def evaluate(context)
      left = @left.evaluate(context)
      right = @right.evaluate(context)

      if not left.type.eql?(right.type)
        raise("Mismatched types '#{left.type}' and '#{right.type}'")
      end

      result = case @op
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
        raise("Invalid binary operator '#{@op}'")
      end

      # since both operands must have same type we can return either as our type
      return Interpreter::Value.new(left.type, result)
    end
  end

  refine IL::UnaryOp do
    def evaluate(context)
      value = @value.evaluate(context)

      result = case @op
      when IL::UnaryOp::NEG_OP
        0 - value.value
      when IL::UnaryOp::POS_OP
        value.value # does nothing
      else
        raise("Invalid unary operator '#{@op}'")
      end

      return Interpreter::Value.new(value.type, result)
    end
  end

  refine IL::Statement do
    extend T::Sig

    sig { params(context: Interpreter::Context).void }
    def interpret(context)
      if self.class == IL::Statement
        raise("#{self.class} is a stub and should not be constructed")
      else
        raise("Interpretation of #{self.class} is not implemented")
      end
    end
  end

  refine IL::Declaration do
    def interpret(context)
      # check for redeclaration
      if context.symbols.include?(@id.name)
        raise("Redeclaration of ID '#{@id.name}'")
      end
      # insert id in symbol table with appropriate type
      rhs_eval = @rhs.evaluate(context)

      # catch type mismatch
      if not rhs_eval.type.eql?(@type)
        raise("Cannot declare ID of type #{@type} with value of type #{rhs_eval.type}")
      end

      context.symbols[@id.name] = Interpreter::SymbolInfo.new(@id.name,
                                                              @type,
                                                              rhs_eval.value)
    end
  end

  refine IL::Assignment do
    def interpret(context)
      # make sure variable has been declared
      if not context.symbols.include?(@id.name)
        raise("Assigning to undefined ID '#{@id.name}'")
      end

      # update value in symbol table
      rhs_eval = @rhs.evaluate(context)

      # catch type mismatch
      info = context.symbols[@id.name]
      if not info # required by sorbet for below usage
        raise("ID #{@name} is defined but has NIL SymbolInfo")
      end
      if not rhs_eval.type.eql?(info.type)
        raise("Cannot assign value of type #{rhs_eval.type} into #{@id.name} (type #{info.type})")
      end

      info.value = rhs_eval.value
    end
  end

  refine IL::Label do
    def interpret(context)
      # empty
    end
  end

  refine IL::Jump do
    def interpret(context)
      # check for invalid target
      if not context.label_indices.include?(@target)
        raise("Invalid jump target '#{@target}'")
      end

      # move instruction pointer there
      index = context.label_indices[@target]
      if not index
        raise("Label #{@target} is defined but has NIL instruction index")
      end
      context.ip = index
    end
  end

  refine IL::JumpZero do
    def interpret(context)
      # evaluate conditional
      cond_eval = @cond.evaluate(context)

      # check for invalid target
      if not context.label_indices.include?(@target)
        raise("Invalid jump target '#{@target}'")
      end

      # move instruction pointer there if zero
      if cond_eval.value == 0
        index = context.label_indices[@target]
        if not index
          raise("Label #{@target} is defined but has NIL instruction index")
        end
        context.ip = index
      end
    end
  end

  refine IL::JumpNotZero do
    def interpret(context)
      # NOTE: virtually identical to JumpZero interpretation
      # evaluate conditional
      cond_eval = @cond.evaluate(context)

      # check for invalid target
      if not context.label_indices.include?(@target)
        raise("Invalid jump target '#{@target}'")
      end

      # move instruction pointer there if not zero
      if cond_eval.value != 0
        index = context.label_indices[@target]
        if not index
          raise("Label #{@target} is defined but has NIL instruction index")
        end
        context.ip = index
      end
    end
  end
end
