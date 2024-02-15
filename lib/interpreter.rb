# typed: true
require "sorbet-runtime"
require_relative "il"

class IL::Value
  sig { params(context: Interpreter::Context).returns(Interpreter::Value) }
  def evaluate(context)
    if self.class == IL::Value
      raise("#{self.class} is a stub and should not be constructed")
    else
      raise("Interpretation of #{self.class} is not implemented")
    end
  end
end

class IL::Constant
  def evaluate(context)
    return Interpreter::Value.new(@type, @value)
  end
end

class IL::ID
  def evaluate(context)
    if not context.symbols.include?(@name)
      raise("Undefined ID #{@name}")
    end

    info = context.symbols[@name]
    return Interpreter::Value.new(info.type, info.value)
  end
end

class IL::Expression
  sig { params(context: Interpreter::Context).returns(Interpreter::Value) }
  def evaluate(context)
    if self.class == IL::Expression
      raise("#{self.class} is a stub and should not be constructed")
    else
      raise("Interpretation of #{self.class} is not implemented")
    end
  end
end

class IL::BinaryOp
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
    else
      raise("Invalid binary operator '#{@op}'")
    end

    # since both operands must have same type we can return either as our type
    return Interpreter::Value.new(left.type, result)
  end
end

class IL::Statement
  sig { params(context: Interpreter::Context).void }
  def interpret(context)
    if self.class == IL::Statement
      raise("#{self.class} is a stub and should not be constructed")
    else
      raise("Interpretation of #{self.class} is not implemented")
    end
  end
end

class IL::Declaration
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

class IL::Assignment
  def interpret(context)
    # make sure variable has been declared
    if not context.symbols.include?(@id.name)
      raise("Assigning to undefined ID '#{@id.name}'")
    end

    # update value in symbol table
    rhs_eval = @rhs.evaluate(context)

    # catch type mismatch
    if not rhs_eval.type.eql?(context.symbols[@id.name].type)
      raise("Cannot assign value of type #{rhs_eval.type} into #{@id.name} (type #{context.symbols[@id.name].type})")
    end

    context.symbols[@id.name].value = rhs_eval.value
  end
end

class IL::Label
  def interpret(context)
    # empty
  end
end

class IL::Jump
  def interpret(context)
    # check for invalid target
    if not context.label_indices.include?(@target)
      raise("Invalid jump target '#{@target}'")
    end

    # move instruction pointer there
    context.ip = context.label_indices[@target]
  end
end

class IL::JumpNotZero
  def interpret(context)
    # evaluate conditional
    cond_eval = @cond.evaluate(context)

    # check for invalid target
    if not context.label_indices.include?(@target)
      raise("Invalid jump target '#{@target}'")
    end

    # move instruction pointer there if not zero
    if cond_eval.value != 0
      context.ip = context.label_indices[@target]
    end
  end
end

module Interpreter
  include Kernel
  extend T::Sig

  class Value
    extend T::Sig

    attr_reader :type
    attr_reader :value

    sig { params(type: String, value: T.untyped).void }
    def initialize(type, value)
      @type = type
      @value = value
    end
  end

  class SymbolInfo
    extend T::Sig

    attr_reader :name
    attr_reader :type
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

    attr_accessor :ip
    attr_reader :symbols
    attr_reader :label_indices

    sig { void }
    def initialize
      @ip = 0
      @symbols = Hash.new
      @label_indices = Hash.new
    end
  end

  sig { params(program: IL::Program).void }
  def self.interpret(program)
    context = Context.new

    # collect all stmts in the program
    stmts = []
    program.each_stmt { |s|
      puts(s.to_s)
      stmts.push(s)
    }

    # register labels
    stmts.each { |s, i|
      if s.is_a?(IL::Label)
        # check for duplicate labels
        if context.label_indices.include?(s.name)
          raise("Multiple definitions of label #{s.name}")
        end
        context.label_indices[s.name] = i
      end
    }

    # interpret
    while context.ip < stmts.length
      s = stmts[context.ip]
      s.interpret(context)
      context.ip += 1
    end

    # TODO: temp sanity check
    puts("Symbol table state:")
    for k in context.symbols.keys
      puts("#{k} = #{context.symbols[k].value} (#{context.symbols[k].type})")
    end
  end
end
